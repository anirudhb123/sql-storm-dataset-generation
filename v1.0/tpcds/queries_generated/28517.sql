
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(NULLIF(ca.ca_street_number, ''), 'N/A') AS street_number,
        COALESCE(NULLIF(ca.ca_street_name, ''), 'Unknown Street') AS street_name,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        c.customer_id,
        c.full_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    JOIN CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_id
)
SELECT 
    customer_id,
    full_name,
    MAX(ws_sales_price) AS max_sales_price,
    MIN(ws_sales_price) AS min_sales_price,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_net_profit) AS total_net_profit,
    STRING_AGG(DISTINCT CONCAT('Item_SK: ', ws_item_sk), ', ') AS items
FROM SalesDetails
WHERE sales_rank <= 5
GROUP BY customer_id, full_name
ORDER BY total_net_profit DESC
LIMIT 10;
