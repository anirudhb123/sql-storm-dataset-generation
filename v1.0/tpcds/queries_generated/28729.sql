
WITH AddressData AS (
    SELECT
        ca_address_id,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),
CustomerFullNames AS (
    SELECT
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
WebSalesData AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit
    FROM
        web_sales
)
SELECT
    CONCAT(c.full_name, ' (', c.c_customer_id, ')') AS customer_info,
    a.full_address,
    SUM(w.ws_sales_price * w.ws_quantity) AS total_sales,
    SUM(w.ws_net_profit) AS total_profit,
    MIN(a.ca_zip) AS zip_code,
    MAX(a.ca_city) AS last_city,
    COUNT(DISTINCT w.ws_order_number) AS order_count
FROM
    CustomerFullNames c
JOIN
    AddressData a ON c.c_customer_id IN (
        SELECT
            ws_bill_customer_sk
        FROM
            WebSalesData w
        )
JOIN
    WebSalesData w ON c.c_customer_sk = w.ws_bill_customer_sk
GROUP BY
    c.full_name, a.full_address
HAVING
    total_sales > 1000
ORDER BY
    total_profit DESC, customer_info;
