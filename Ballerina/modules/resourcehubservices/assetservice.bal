import ballerina/http;
import ballerina/sql;
import ballerina/io;

public type Asset record {|
    int id;
    string asset_name;
    string category;
    int quantity;
    string condition_type;
    string location;
|};

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173", "*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type"]
    }
}

service /asset on ln{
    resource function get details() returns Asset[]|error{
        stream<Asset, sql:Error?> resultStream = dbClient->query(`SELECT * FROM assets`);

        Asset[] assets = [];
        check resultStream.forEach(function(Asset asset){
            assets.push(asset);
        });

        return assets;
    }
}
public function startAssetService() returns error? {
    io:println("Assets service started on port 9090");
}
