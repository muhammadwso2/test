import ballerinax/snowflake;
import ballerinax/snowflake.driver as _;
import ballerina/http;
import ballerina/sql;
import ballerina/time;

// Configure Snowflake client options with proper connection properties
snowflake:Options snowflakeOptions = {
    properties: {
        "JDBC_QUERY_RESULT_FORMAT": "JSON",
        "db": snowflakeDatabase,
        "warehouse": snowflakeWarehouse,
        "schema": snowflakeSchema,
        "ssl": "on",
        "tracing": "OFF"
    }
};

// Initialize Snowflake client at module level
snowflake:Client snowflakeClient = check new (
    snowflakeAccount,
    snowflakeUser,
    snowflakePassword,
    snowflakeOptions
);

// Initialize HTTP client for Snowflake service using configurable host
http:Client snowflakeServiceClient = check new (snowflakeServiceUrl);

// ETL Service - Only expense-reports resource
service /etl on new http:Listener(etlServicePort) {

    // ETL endpoint - GET /etl/expense-reports (Only remaining resource)
    resource function get 'expense\-reports(string? employeeName, string? status, string? dateFrom, string? dateTo) returns EtlResponse {
        time:Utc startTime = time:utcNow();
        string processedAt = time:utcToString(startTime);
        
        // Initialize response
        EtlResponse etlResponse = {
            success: false,
            message: "",
            totalRecordsExtracted: 0,
            validRecords: 0,
            invalidRecords: 0,
            recordsLoaded: 0,
            processedAt: processedAt
        };
        
        do {
            // Step 1: Extract data from SAP Concur using HTTP client
            ExpenseReportsResponse sapResponse = check extractExpenseReportsViaHttp(sapConcurClient, employeeName, status);
            etlResponse.totalRecordsExtracted = sapResponse.Reports.length();
            
            if sapResponse.Reports.length() == 0 {
                etlResponse.success = true;
                etlResponse.message = "No expense reports found matching the criteria";
                return etlResponse;
            }
            
            // Step 2: Transform and validate data
            TransformedExpenseReport[] validReports = [];
            string[] allErrors = [];
            
            foreach ExpenseReport report in sapResponse.Reports {
                ValidationResult validation = validateExpenseReport(report);
                
                if validation.isValid {
                    TransformedExpenseReport transformedReport = transformExpenseReport(report);
                    validReports.push(transformedReport);
                    etlResponse.validRecords += 1;
                } else {
                    etlResponse.invalidRecords += 1;
                    foreach string validationError in validation.errors {
                        allErrors.push("Report " + report.ReportID + ": " + validationError);
                    }
                }
            }
            
            // Step 3: Create expense reports table if not exists
            sql:ExecutionResult|error tableResult = createExpenseReportsTable(snowflakeClient);
            if tableResult is error {
                etlResponse.message = "Failed to create expense reports table: " + tableResult.message();
                etlResponse.errors = allErrors;
                return etlResponse;
            }
            
            // Step 4: Load valid data into Snowflake using batch-insert endpoint
            if validReports.length() > 0 {
                ApiResponse|error insertResult = loadDataToSnowflakeViaBatchInsert(snowflakeServiceClient, validReports);
                
                if insertResult is ApiResponse {
                    if insertResult.success {
                        etlResponse.recordsLoaded = validReports.length();
                        etlResponse.success = true;
                        etlResponse.message = string `ETL process completed successfully. Extracted: ${etlResponse.totalRecordsExtracted}, Valid: ${etlResponse.validRecords}, Invalid: ${etlResponse.invalidRecords}, Loaded: ${etlResponse.recordsLoaded}`;
                        
                        if allErrors.length() > 0 {
                            etlResponse.errors = allErrors;
                        }
                    } else {
                        etlResponse.message = "Failed to load data into Snowflake: " + insertResult.message;
                        etlResponse.errors = allErrors;
                    }
                } else {
                    etlResponse.message = "Failed to call Snowflake batch-insert: " + insertResult.message();
                    etlResponse.errors = allErrors;
                }
            } else {
                etlResponse.success = true;
                etlResponse.message = "No valid records to load after validation";
                etlResponse.errors = allErrors;
            }
            
        } on fail error e {
            etlResponse.message = "ETL process failed: " + e.message();
        }
        
        return etlResponse;
    }
}

// HTTP service for Snowflake operations
service /snowflake on new http:Listener(servicePort) {

    // Query endpoint - GET /snowflake/query
    resource function get query(string sqlQuery) returns QueryResponse[]|ApiResponse {
        do {
            sql:ParameterizedQuery query = `${sqlQuery}`;
            stream<QueryResponse, sql:Error?> resultStream = snowflakeClient->query(query);
            
            QueryResponse[] results = [];
            check from QueryResponse result in resultStream
                do {
                    results.push(result);
                };
            
            return results;
        } on fail error e {
            return {
                success: false,
                message: "Query execution failed: " + e.message()
            };
        }
    }

    // Insert single record - POST /snowflake/insert
    resource function post insert(@http:Payload InsertRequest insertData) returns ApiResponse {
        do {
            sql:ParameterizedQuery insertQuery = `INSERT INTO users (name, age, email) VALUES (${insertData.name}, ${insertData.age}, ${insertData.email})`;
            sql:ExecutionResult result = check snowflakeClient->execute(insertQuery);
            
            return {
                success: true,
                message: "Record inserted successfully",
                data: {
                    affectedRowCount: result.affectedRowCount,
                    lastInsertId: result.lastInsertId
                }
            };
        } on fail error e {
            return {
                success: false,
                message: "Insert operation failed: " + e.message()
            };
        }
    }

    // Batch insert records - POST /snowflake/batch-insert
    resource function post 'batch\-insert(@http:Payload BatchInsertRequest batchData) returns ApiResponse {
        do {
            sql:ParameterizedQuery[] batchQueries = [];
            
            foreach InsertRequest insertRecord in batchData.records {
                sql:ParameterizedQuery insertQuery = `INSERT INTO users (name, age, email) VALUES (${insertRecord.name}, ${insertRecord.age}, ${insertRecord.email})`;
                batchQueries.push(insertQuery);
            }
            
            sql:ExecutionResult[] results = check snowflakeClient->batchExecute(batchQueries);
            
            int totalAffectedRows = 0;
            foreach sql:ExecutionResult result in results {
                int? affectedCount = result.affectedRowCount;
                if affectedCount is int {
                    totalAffectedRows += affectedCount;
                }
            }
            
            return {
                success: true,
                message: "Batch insert completed successfully",
                data: {
                    totalRecords: batchData.records.length(),
                    totalAffectedRows: totalAffectedRows
                }
            };
        } on fail error e {
            return {
                success: false,
                message: "Batch insert operation failed: " + e.message()
            };
        }
    }

    // Delete record - DELETE /snowflake/delete
    resource function delete delete(int id) returns ApiResponse {
        do {
            sql:ParameterizedQuery deleteQuery = `DELETE FROM users WHERE id = ${id}`;
            sql:ExecutionResult result = check snowflakeClient->execute(deleteQuery);
            
            return {
                success: true,
                message: "Record deleted successfully",
                data: {
                    affectedRowCount: result.affectedRowCount
                }
            };
        } on fail error e {
            return {
                success: false,
                message: "Delete operation failed: " + e.message()
            };
        }
    }

    // Update record - PUT /snowflake/update
    resource function put update(int id, @http:Payload InsertRequest updateData) returns ApiResponse {
        do {
            sql:ParameterizedQuery updateQuery = `UPDATE users SET name = ${updateData.name}, age = ${updateData.age}, email = ${updateData.email} WHERE id = ${id}`;
            sql:ExecutionResult result = check snowflakeClient->execute(updateQuery);
            
            return {
                success: true,
                message: "Record updated successfully",
                data: {
                    affectedRowCount: result.affectedRowCount
                }
            };
        } on fail error e {
            return {
                success: false,
                message: "Update operation failed: " + e.message()
            };
        }
    }

    // Get single record by ID - GET /snowflake/user/{id}
    resource function get user/[int id]() returns QueryResponse|ApiResponse {
        do {
            sql:ParameterizedQuery selectQuery = `SELECT id, name, age, email FROM users WHERE id = ${id}`;
            QueryResponse result = check snowflakeClient->queryRow(selectQuery);
            
            return result;
        } on fail error e {
            return {
                success: false,
                message: "Failed to fetch user: " + e.message()
            };
        }
    }

    // Create table endpoint - POST /snowflake/create-table
    resource function post 'create\-table() returns ApiResponse {
        do {
            sql:ExecutionResult result = check snowflakeClient->execute(`CREATE TABLE IF NOT EXISTS users (
                ID INT NOT NULL AUTOINCREMENT,
                name VARCHAR(255),
                age INT,
                email VARCHAR(255),
                PRIMARY KEY (ID)
            )`);
            
            return {
                success: true,
                message: "Table created successfully",
                data: {
                    affectedRowCount: result.affectedRowCount
                }
            };
        } on fail error e {
            return {
                success: false,
                message: "Table creation failed: " + e.message()
            };
        }
    }
}