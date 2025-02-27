
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
ReturnInfo AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(wr.wr_order_number) AS return_count
    FROM web_returns wr
    GROUP BY wr.refunded_customer_sk
),
BenchmarkData AS (
    SELECT 
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SI.total_sales,
        SI.order_count,
        RI.total_returns,
        RI.return_count
    FROM AddressInfo ca
    JOIN CustomerDetails cd ON ca.ca_address_sk = cd.c_customer_sk
    LEFT JOIN SalesInfo SI ON cd.c_customer_sk = SI.ws_bill_customer_sk
    LEFT JOIN ReturnInfo RI ON cd.c_customer_sk = RI.refunded_customer_sk
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    full_name,
    cd_gender,
    cd_marital_status,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    COALESCE(total_returns, 0) AS total_returns,
    COALESCE(return_count, 0) AS return_count,
    (COALESCE(total_sales, 0) - COALESCE(total_returns, 0)) AS net_profit
FROM BenchmarkData
WHERE cd_gender = 'F'
ORDER BY net_profit DESC
LIMIT 100;
