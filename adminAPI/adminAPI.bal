// import ballerina/io;
import ballerina/http;
import ballerinax/mysql;
import ballerina/sql;
import ballerinax/mysql.driver as _;

type Product record {|
    int productId;
    string productName;
    string description;
    decimal unitPrice;
|};

configurable string host = ?;
configurable string user = ?;
configurable string password = ?;
configurable string database = ?;

// set CORS headers
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["Authorization"],
        exposeHeaders: ["*"],
        maxAge: 84900
    }
}
service / on new http:Listener(9090) {

    private final mysql:Client db;

    function init() returns error? {
        self.db = check new (host, user, password, database, 3306);
    }

    resource function post products(@http:Payload Product product) returns Product|error? {
        // insert the product to the database and return the product
        sql:ExecutionResult result = check self.db->execute(`INSERT INTO ce_products (productName, description, unitPrice) VALUES (${product.productName}, ${product.description}, ${product.unitPrice})`);
        var productId = result.lastInsertId;
        if productId is int {
            product.productId = productId;
            return product;
        } else {
            return error("Error while retrieving the last inserted product id");
        }
    }

    resource function put products(@http:Payload Product product) returns Product|error? {
        // update the product in the database and return the product
        _ = check self.db->execute(`UPDATE ce_products SET productName = ${product.productName}, description = ${product.description}, unitPrice = ${product.unitPrice} WHERE productId = ${product.productId}`);
        return product;
    }

    
    resource function get products() returns Product[]|error? {
        // retrieve all the products from the database and return them
        stream<Product, sql:Error?> resultStream = self.db->query(`SELECT * FROM ce_products`);
        Product[] products = check from Product p in resultStream select p;
        return products;
    }
}
