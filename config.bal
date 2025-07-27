// Host configuration - configurable property for localhost
configurable string hostName = "localhost";

// Configurable variables for Snowflake connection
configurable string snowflakeAccount = ?;
configurable string snowflakeUser = ?;
configurable string snowflakePassword = ?;
configurable string snowflakeDatabase = ?;
configurable string snowflakeWarehouse = "COMPUTE_WH";
configurable string snowflakeSchema = "PUBLIC";
configurable int servicePort = 8080;
configurable int etlServicePort = 8082;

// SAP Concur mock service configuration
configurable int sapConcurPort = 8081;

// SAP Concur API configuration - using configurable host
configurable string sapConcurUrl = "http://" + hostName + ":" + sapConcurPort.toString() + "/sap-concur";
configurable string sapConcurApiKey = "mock-api-key";

// Snowflake service URL - using configurable host
configurable string snowflakeServiceUrl = "http://" + hostName + ":" + servicePort.toString();