import ballerina/log;

// Agent configuration for monitoring and processing
public type AgentConfig record {|
    string name;
    int intervalSeconds;
    boolean enabled;
|};

// ETL monitoring agent
public class EtlMonitoringAgent {
    private AgentConfig config;
    private boolean running = false;

    public function init(AgentConfig agentConfig) {
        self.config = agentConfig;
    }

    // Start the monitoring agent
    public function startAgent() returns error? {
        if self.running {
            return error("Agent is already running");
        }

        self.running = true;
        log:printInfo("ETL Monitoring Agent started: " + self.config.name);

        // This would typically run in a separate thread/worker
        // For now, we'll just log the start
        return;
    }

    // Stop the monitoring agent
    public function stopAgent() {
        self.running = false;
        log:printInfo("ETL Monitoring Agent stopped: " + self.config.name);
    }

    // Check if agent is running
    public function isRunning() returns boolean {
        return self.running;
    }

    // Get agent status
    public function getStatus() returns record {|string name; boolean running; int intervalSeconds;|} {
        return {
            name: self.config.name,
            running: self.running,
            intervalSeconds: self.config.intervalSeconds
        };
    }
}

// Data quality agent
public class DataQualityAgent {
    private AgentConfig config;
    private boolean running = false;

    public function init(AgentConfig agentConfig) {
        self.config = agentConfig;
    }

    // Start the data quality agent
    public function startAgent() returns error? {
        if self.running {
            return error("Data Quality Agent is already running");
        }

        self.running = true;
        log:printInfo("Data Quality Agent started: " + self.config.name);
        return;
    }

    // Stop the data quality agent
    public function stopAgent() {
        self.running = false;
        log:printInfo("Data Quality Agent stopped: " + self.config.name);
    }

    // Check data quality metrics
    public function checkDataQuality() returns record {|int totalRecords; int validRecords; decimal qualityScore;|} {
        // Mock data quality check
        return {
            totalRecords: 100,
            validRecords: 95,
            qualityScore: 95.0
        };
    }

    // Get agent status
    public function getStatus() returns record {|string name; boolean running; int intervalSeconds;|} {
        return {
            name: self.config.name,
            running: self.running,
            intervalSeconds: self.config.intervalSeconds
        };
    }
}

// Initialize agents
EtlMonitoringAgent etlAgent = new ({
    name: "ETL-Monitor",
    intervalSeconds: 300,
    enabled: true
});

DataQualityAgent qualityAgent = new ({
    name: "Data-Quality-Monitor",
    intervalSeconds: 600,
    enabled: true
});

// Agent management functions
public function startAllAgents() returns error? {
    check etlAgent.startAgent();
    check qualityAgent.startAgent();
    log:printInfo("All agents started successfully");
}

public function stopAllAgents() {
    etlAgent.stopAgent();
    qualityAgent.stopAgent();
    log:printInfo("All agents stopped");
}

public function getAgentStatuses() returns record {|anydata etlAgent; anydata qualityAgent;|} {
    return {
        etlAgent: etlAgent.getStatus(),
        qualityAgent: qualityAgent.getStatus()
    };
}