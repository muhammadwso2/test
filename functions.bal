import ballerinax/snowflake;
import ballerina/sql;
import ballerina/http;

// Create expense reports table in Snowflake
public function createExpenseReportsTable(snowflake:Client snowflakeClient) returns sql:ExecutionResult|error {
    sql:ParameterizedQuery createTableQuery = `
        CREATE TABLE IF NOT EXISTS expense_reports (
            id INT NOT NULL AUTOINCREMENT,
            report_id VARCHAR(50) NOT NULL,
            employee_name VARCHAR(255) NOT NULL,
            amount DECIMAL(10,2) NOT NULL,
            currency VARCHAR(10) NOT NULL,
            submitted_date DATE NOT NULL,
            status VARCHAR(50) NOT NULL,
            processed_date TIMESTAMP NOT NULL,
            PRIMARY KEY (id),
            UNIQUE (report_id)
        )
    `;
    
    return snowflakeClient->execute(createTableQuery);
}

// Insert transformed expense reports into Snowflake
public function insertExpenseReports(snowflake:Client snowflakeClient, TransformedExpenseReport[] reports) returns sql:ExecutionResult[]|error {
    sql:ParameterizedQuery[] batchQueries = [];
    
    foreach TransformedExpenseReport report in reports {
        sql:ParameterizedQuery insertQuery = `
            INSERT INTO expense_reports (report_id, employee_name, amount, currency, submitted_date, status, processed_date)
            VALUES (${report.reportId}, ${report.employeeName}, ${report.amount}, ${report.currency}, 
                    ${report.submittedDate}, ${report.status}, ${report.processedDate})
        `;
        batchQueries.push(insertQuery);
    }
    
    return snowflakeClient->batchExecute(batchQueries);
}

// Extract expense reports from SAP Concur via HTTP
public function extractExpenseReportsViaHttp(http:Client sapClient, string? employeeName, string? status) returns ExpenseReportsResponse|error {
    string endpoint = "/expense/reports";
    
    // Determine endpoint based on filters
    if employeeName is string {
        endpoint = "/expense/reports/employee/" + employeeName;
    } else if status is string {
        endpoint = "/expense/reports/status/" + status;
    }
    
    ExpenseReportsResponse response = check sapClient->get(endpoint);
    return response;
}

// Load data to Snowflake via batch-insert endpoint
public function loadDataToSnowflakeViaBatchInsert(http:Client snowflakeClient, TransformedExpenseReport[] reports) returns ApiResponse|error {
    // Convert TransformedExpenseReport to InsertRequest format for batch insert
    InsertRequest[] insertRecords = [];
    
    foreach TransformedExpenseReport report in reports {
        InsertRequest insertRecord = {
            name: report.employeeName,
            age: 0, // Default age since expense reports don't have age
            email: report.employeeName + "@company.com" // Generate email from employee name
        };
        insertRecords.push(insertRecord);
    }
    
    BatchInsertRequest batchRequest = {
        records: insertRecords
    };
    
    ApiResponse response = check snowflakeClient->post("/snowflake/batch-insert", batchRequest);
    return response;
}

// Extract expense reports from SAP Concur (legacy function - kept for compatibility)
public function extractExpenseReports(http:Client sapClient, EtlRequest etlRequest) returns ExpenseReportsResponse|error {
    string endpoint = "/expense/reports";
    
    // Add query parameters based on ETL request
    string? employeeName = etlRequest.employeeName;
    string? status = etlRequest.status;
    
    if employeeName is string {
        endpoint = "/expense/reports/employee/" + employeeName;
    } else if status is string {
        endpoint = "/expense/reports/status/" + status;
    }
    
    ExpenseReportsResponse response = check sapClient->get(endpoint);
    return response;
}