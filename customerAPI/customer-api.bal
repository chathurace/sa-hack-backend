import ballerina/io;
import ballerina/graphql;
import ballerinax/mysql;
import ballerina/sql;
import ballerinax/mysql.driver as _;

type Product record {|
    int productId;
    string productName;
    string description;
    decimal unitPrice;
|};

type CartItem record {|
    int productId;
    string productName;
    decimal unitPrice;
    int quantity;
    decimal total = 0;
|};

type UserCartItem record {|
    string username;
    int productId;
    string productName;
    decimal unitPrice;
    int quantity;
    decimal total = 0;
|};

configurable string host = ?;
configurable string user = ?;
configurable string password = ?;
configurable string database = ?;

service /shop1 on new graphql:Listener(9090) {

    private final mysql:Client db;

    function init() returns error? {
        self.db = check new (host, user, password, database, 3306);
    }

    resource function get products() returns Product[]|error? {
        // retrieve all the products from the database and return them
        stream<Product, sql:Error?> resultStream = self.db->query(`SELECT * FROM ce_products`);
        Product[] products = check from Product p in resultStream select p;
        return products;
    }

    resource function get cart (string userName) returns CartItem[]|error {

        // select all the cart items for the given user from the database
        // and return them as an array
        sql:ParameterizedQuery query = `SELECT p.productId, p.productName, p.unitPrice, c.quantity
            FROM ce_cart_items c, ce_products p
            WHERE c.productId = p.productId AND c.username = ${userName}`;
        stream<CartItem, sql:Error?> resultStream = self.db->query(query);
        CartItem[] cart = check from CartItem c in resultStream select c;
        return cart;

        // CartItem c1 = {productId: 1, productName: "Ballerina", unitPrice: 100.0, quantity: 2, total: 200.0};
        // CartItem c2 = {productId: 2, productName: "GraphQL", unitPrice: 200.0, quantity: 1, total: 200.0};

        // CartItem[] cart = [c1, c2];
        // return cart;
    }

    remote function addCartItem (UserCartItem cartItem) returns int|error? {
        // add the cart item to the database
        sql:ParameterizedQuery query = `INSERT INTO ce_cart_items (username, productId, quantity)
            VALUES (${cartItem.username}, ${cartItem.productId}, ${cartItem.quantity})`;
        sql:ExecutionResult result = check self.db->execute(query);

        var rid = result.lastInsertId;
        if (rid is int) {
            return rid;
        } else {
            return error("Error while retrieving the last inserted id");
        }
    }
}

public function main() {
    io:println("Hello, World!");
}
