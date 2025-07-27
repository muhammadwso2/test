import ballerina/time;

// Transform SAP Concur expense report to Snowflake format
public function transformExpenseReport(ExpenseReport sapReport) returns TransformedExpenseReport {
    time:Utc currentTime = time:utcNow();
    string processedDate = time:utcToString(currentTime);
    
    return {
        reportId: sapReport.ReportID,
        employeeName: sapReport.Employee,
        amount: sapReport.Amount,
        currency: sapReport.Currency,
        submittedDate: sapReport.SubmittedDate,
        status: sapReport.Status,
        processedDate: processedDate
    };
}

// Validate expense report data
public function validateExpenseReport(ExpenseReport report) returns ValidationResult {
    string[] errors = [];
    
    // Validate ReportID
    string trimmedReportId = report.ReportID.trim();
    if trimmedReportId.length() == 0 {
        errors.push("ReportID cannot be empty");
    }
    
    // Validate Employee name
    string trimmedEmployee = report.Employee.trim();
    if trimmedEmployee.length() == 0 {
        errors.push("Employee name cannot be empty");
    }
    
    // Validate Amount
    if report.Amount <= 0.0d {
        errors.push("Amount must be greater than 0");
    }
    
    // Validate Currency
    string trimmedCurrency = report.Currency.trim();
    if trimmedCurrency.length() == 0 {
        errors.push("Currency cannot be empty");
    }
    
    // Validate Status
    string[] validStatuses = ["Submitted", "Approved", "Rejected", "Pending"];
    boolean validStatus = false;
    foreach string status in validStatuses {
        if report.Status == status {
            validStatus = true;
            break;
        }
    }
    if !validStatus {
        errors.push("Invalid status: " + report.Status);
    }
    
    return {
        isValid: errors.length() == 0,
        errors: errors
    };
}