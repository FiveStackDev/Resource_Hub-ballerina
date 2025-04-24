import ballerina/http;
import ballerina/io;
import ballerina/sql;

public type AssetRequest record {|
    int id?;
    string username;
    string profile_picture_url;
    string asset_name;
    string category;
    string borrowed_date;
    string handover_date;
    int remaining_days;
    int quantity;

|};

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173", "*"],
        allowMethods: ["GET", "POST", "DELETE", "OPTION", "PUT"],
        allowHeaders: ["Content-Type"]
    }
}

service /assetrequest on ln {
    resource function get details() returns AssetRequest[]|error {
        stream<AssetRequest, sql:Error?> resultstream = dbClient->query
        (`SELECT 
         u.profile_picture_url,
        u.username,
        a.id,
        a.asset_name,
        a.category,
        ar.borrowed_date,
        ar.handover_date,
        DATEDIFF(ar.handover_date, CURDATE()) AS remaining_days,
        ar.quantity
        FROM assetrequests ar
        JOIN users u ON ar.user_id = u.id
        JOIN assets a ON ar.asset_id = a.id;`);

        AssetRequest[] assetrequests = [];

        check resultstream.forEach(function(AssetRequest assetrequest) {
            assetrequests.push(assetrequest);
        });

        return assetrequests;
    }

    resource function post add(@http:Payload AssetRequest assetrequest) returns json|error {
        io:println("Received Asset Request data: " + assetrequest.toJsonString());

        sql:ExecutionResult result = check dbClient->execute(`
            INSERT INTO assetrequests (user_id, asset_id, borrowed_date, handover_date, quantity)
            VALUES (${assetrequest.username}, ${assetrequest.asset_name}, ${assetrequest.borrowed_date}, ${assetrequest.handover_date}, ${assetrequest.quantity})
        `);

        int|string? lastInsertId = result.lastInsertId;
        if lastInsertId is int {
            assetrequest.id = lastInsertId;
        }

        return {
            message: "Asset request added successfully",
            assetrequest: assetrequest
        };
    }

    resource function delete details/[int id]() returns json|error {
        sql:ExecutionResult result = check dbClient->execute(`
            DELETE FROM assetrequests WHERE id = ${id}
        `);

        if result.affectedRowCount == 0 {
            return {
                message: "Asset request not found"
            };
        }
        return {
            message: "Asset request deleted successfully"
        };
    }

    resource function put details/[int id](@http:Payload AssetRequest assetrequest) returns json|error {
        sql:ExecutionResult result = check dbClient->execute(`
            UPDATE assetrequests 
            SET user_id = ${assetrequest.username}, asset_id = ${assetrequest.asset_name}, borrowed_date = ${assetrequest.borrowed_date}, handover_date = ${assetrequest.handover_date}, quantity = ${assetrequest.quantity}
            WHERE id = ${id}
        `);

        if result.affectedRowCount == 0 {
            return {
                message: "Asset request not found"
            };
        }

        return {
            message: "Asset request updated successfully",
            assetrequest: assetrequest
        };
    }
        resource function get dueassets() returns AssetRequest[]|error {
        stream<AssetRequest, sql:Error?> resultstream = dbClient->query
        (`SELECT 
        u.profile_picture_url,
        u.username,
        a.id,
        a.asset_name,
        a.category,
        ar.borrowed_date,
        ar.handover_date,
        DATEDIFF(ar.handover_date, CURDATE()) AS remaining_days,
        ar.quantity
        FROM assetrequests ar
        JOIN users u ON ar.user_id = u.id
        JOIN assets a ON ar.asset_id = a.id
        WHERE DATEDIFF(ar.handover_date, CURDATE()) < 0
        ORDER BY remaining_days ASC;`
        );

        AssetRequest[] assetrequests = [];

        check resultstream.forEach(function(AssetRequest assetrequest) {
            assetrequests.push(assetrequest);
        });

        return assetrequests;
    }
}

public function AssetRequestService() {
    io:println("Asset request service work on port :9090");
}