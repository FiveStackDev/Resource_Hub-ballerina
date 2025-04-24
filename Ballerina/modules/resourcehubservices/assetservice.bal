import ballerina/http;
import ballerina/sql;
import ballerina/io;

public type Asset record {|
    int id?;
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
resource function post add(@http:Payload Asset asset) returns json|error {

    sql:ExecutionResult result = check dbClient->execute(
        `insert into assets (asset_name, category, quantity, condition_type, location) 
          values (${asset.asset_name}, ${asset.category}, ${asset.quantity}, ${asset.condition_type}, ${asset.location})`
    );

    if result.affectedRowCount == 0 {
        return {
            message: "Failed to add asset"
        };
    }
    return {
        message: "Asset added successfully",
        asset: asset
    };
}


     resource function put details/[int id](@http:Payload Asset asset) returns json|error {
        sql:ExecutionResult result = check dbClient->execute(`
            UPDATE assets 
            SET asset_name = ${asset.asset_name}, category = ${asset.category}, quantity = ${asset.quantity}, condition_type = ${asset.condition_type}, location = ${asset.location}
            WHERE id = ${id}
        `);

        if result.affectedRowCount == 0 {
            return {
                message: "Asset not found"
            };
        }

        return {
            message: "Asset updated successfully",
            asset: asset
        };
    }

    resource function delete details/[int id]() returns json|error {
        sql:ExecutionResult result = check dbClient->execute(`
            DELETE FROM assets WHERE id = ${id}
        `);

        if result.affectedRowCount == 0 {
            return {
                message: "asset not found"
            };
        }

        return {
            message: "asset deleted successfully"
        };
    }


}
public function startAssetService() returns error? {
    io:println("Assets service started on port 9090");
}
