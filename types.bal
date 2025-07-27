// Record types for API requests and responses
public type QueryRequest record {|
    string sqlQuery;
|};

public type InsertRequest record {|
    string name;
    int age;
    string email;
|};

public type BatchInsertRequest record {|
    InsertRequest[] records;
|};

public type DeleteRequest record {|
    int id;
|};

public type QueryResponse record {|
    int id;
    string name;
    int age;
    string email;
|};

public type ApiResponse record {|
    boolean success;
    string message;
    anydata data?;
    string[] errors?;
|};

// SAP Concur mock service types
public type ExpenseReport record {|
    string ReportID;
    string Employee;
    decimal Amount;
    string Currency;
    string SubmittedDate;
    string Status;
|};

public type ExpenseReportsResponse record {|
    ExpenseReport[] Reports;
|};

public type Employee record {|
    string EmployeeID;
    string Name;
    string Department;
    string Email;
    string Manager;
    string Status;
|};

public type EmployeeDataResponse record {|
    Employee[] Employees;
|};

// ETL specific types
public type TransformedExpenseReport record {|
    string reportId;
    string employeeName;
    decimal amount;
    string currency;
    string submittedDate;
    string status;
    string processedDate;
|};

public type EtlRequest record {|
    string? employeeName;
    string? status;
    string? dateFrom;
    string? dateTo;
|};

public type EtlResponse record {|
    boolean success;
    string message;
    int totalRecordsExtracted;
    int validRecords;
    int invalidRecords;
    int recordsLoaded;
    string[] errors?;
    string processedAt;
|};

public type ValidationResult record {|
    boolean isValid;
    string[] errors;
|};