import ballerina/http;
import ballerina/io;
import ballerina/sql;

public type Maintenance record {| 
    int id?; 
    int user_id; 
    string name; 
    string description; 
    string priorityLevel; 
    string status; 
    string request_date; 
    string profilePicture; 
|};

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173", "*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type"]
    }
}

service /maintenance on ln {
    resource function get details() returns Maintenance[]|error {
        stream<Maintenance, sql:Error?> resultStream =
            dbClient->query(`SELECT 
                u.profile_picture_url AS profilePicture,
                u.username AS name,
                m.description,
                m.priority_level AS priorityLevel,
                m.status,
                m.request_date,
                m.id 
                FROM maintenance m
                JOIN users u ON m.user_id = u.id;
        `);

        Maintenance[] maintenances = [];
        check resultStream.forEach(function(Maintenance maintenance) {
            maintenances.push(maintenance);
        });

        return maintenances;
    }
}

public function maintenancesManagementService() returns error? {
    io:println("maintenancesManagement service started on port: 9090");
}
