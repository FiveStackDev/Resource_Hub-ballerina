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
        allowOrigins: ["http://localhost:9090", "*"],
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
}

public function AssetRequestService() {
    io:println("Asset request service work on port 9090");
}
