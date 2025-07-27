import ballerina/http;
import ballerina/log;

// Mock data for expense reports
ExpenseReport[] mockExpenseReports = [
    {
        ReportID: "RPT001",
        Employee: "Ali",
        Amount: 320.45,
        Currency: "USD",
        SubmittedDate: "2024-07-12",
        Status: "Submitted"
    },
    {
        ReportID: "RPT002",
        Employee: "Sara",
        Amount: 540.00,
        Currency: "USD",
        SubmittedDate: "2024-07-18",
        Status: "Approved"
    },
    {
        ReportID: "RPT003",
        Employee: "John",
        Amount: 275.30,
        Currency: "USD",
        SubmittedDate: "2024-07-20",
        Status: "Pending"
    },
    {
        ReportID: "RPT004",
        Employee: "Maria",
        Amount: 890.75,
        Currency: "USD",
        SubmittedDate: "2024-07-15",
        Status: "Approved"
    },
    {
        ReportID: "RPT005",
        Employee: "David",
        Amount: 156.20,
        Currency: "USD",
        SubmittedDate: "2024-07-22",
        Status: "Rejected"
    }
];

// Mock data for employee information
Employee[] mockEmployees = [
    {
        EmployeeID: "EMP001",
        Name: "Ali",
        Department: "Sales",
        Email: "ali@company.com",
        Manager: "Robert Smith",
        Status: "Active"
    },
    {
        EmployeeID: "EMP002",
        Name: "Sara",
        Department: "Marketing",
        Email: "sara@company.com",
        Manager: "Jennifer Davis",
        Status: "Active"
    },
    {
        EmployeeID: "EMP003",
        Name: "John",
        Department: "Engineering",
        Email: "john@company.com",
        Manager: "Michael Johnson",
        Status: "Active"
    },
    {
        EmployeeID: "EMP004",
        Name: "Maria",
        Department: "Finance",
        Email: "maria@company.com",
        Manager: "Lisa Wilson",
        Status: "Active"
    },
    {
        EmployeeID: "EMP005",
        Name: "David",
        Department: "HR",
        Email: "david@company.com",
        Manager: "Sarah Brown",
        Status: "Active"
    }
];

// SAP Concur Mock HTTP Service
service /sap\-concur on new http:Listener(sapConcurPort) {

    // Get all expense reports - GET /sap-concur/expense/reports
    resource function get expense/reports() returns ExpenseReportsResponse {
        log:printDebug(mockExpenseReports.toString());
        return {
            Reports: mockExpenseReports
        };
    }

    // Get expense report by ID - GET /sap-concur/expense/reports/{reportId}
    resource function get expense/reports/[string reportId]() returns ExpenseReport|http:NotFound {
        foreach ExpenseReport report in mockExpenseReports {
            if report.ReportID == reportId {
                return report;
            }
        }
        return http:NOT_FOUND;
    }

    // Get all employee data - GET /sap-concur/employee/data
    resource function get employee/data() returns EmployeeDataResponse {
        return {
            Employees: mockEmployees
        };
    }

    // Get employee by ID - GET /sap-concur/employee/data/{employeeId}
    resource function get employee/data/[string employeeId]() returns Employee|http:NotFound {
        foreach Employee employee in mockEmployees {
            if employee.EmployeeID == employeeId {
                return employee;
            }
        }
        return http:NOT_FOUND;
    }

    // Get employee by name - GET /sap-concur/employee/name/{employeeName}
    resource function get employee/name/[string employeeName]() returns Employee|http:NotFound {
        foreach Employee employee in mockEmployees {
            if employee.Name == employeeName {
                return employee;
            }
        }
        return http:NOT_FOUND;
    }

    // Get expense reports by employee name - GET /sap-concur/expense/reports/employee/{employeeName}
    resource function get expense/reports/employee/[string employeeName]() returns ExpenseReportsResponse {
        ExpenseReport[] filteredReports = [];
        foreach ExpenseReport report in mockExpenseReports {
            if report.Employee == employeeName {
                filteredReports.push(report);
            }
        }
        return {
            Reports: filteredReports
        };
    }

    // Get expense reports by status - GET /sap-concur/expense/reports/status/{status}
    resource function get expense/reports/status/[string status]() returns ExpenseReportsResponse {
        ExpenseReport[] filteredReports = [];
        foreach ExpenseReport report in mockExpenseReports {
            if report.Status == status {
                filteredReports.push(report);
            }
        }
        return {
            Reports: filteredReports
        };
    }

    // Health check endpoint - GET /sap-concur/health
    resource function get health() returns record {|string status; string message;|} {
        return {
            status: "UP",
            message: "SAP Concur Mock Service is running"
        };
    }
}
