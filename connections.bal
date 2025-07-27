import ballerina/http;

// SAP Concur client configuration
http:ClientConfiguration sapClientConfig = {
    timeout: 30
};

// Initialize HTTP client for SAP Concur API using configurable host
http:Client sapConcurClient = check new (sapConcurUrl, sapClientConfig);