
WITH CustomerFullName AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales AS ws
    JOIN CustomerFullName AS cf ON ws.ws_bill_customer_sk = cf.c_customer_sk
    WHERE cf.cd_gender = 'F' AND cf.cd_marital_status = 'M'
    GROUP BY ws.ws_ship_date_sk, ws.ws_item_sk
),
AggregatedSales AS (
    SELECT 
        d.d_date AS sale_date,
        sd.ws_item_sk,
        COUNT(sd.total_quantity) AS number_of_sales,
        SUM(sd.total_net_profit) AS total_net_profit
    FROM SalesData AS sd
    JOIN date_dim AS d ON sd.ws_ship_date_sk = d.d_date_sk
    GROUP BY d.d_date, sd.ws_item_sk
)
SELECT 
    TRUNC(ABS(total_net_profit)) AS rounded_profit,
    COUNT(*) AS number_of_sales,
    MAX(sale_date) AS last_sale_date
FROM AggregatedSales
WHERE total_net_profit > 1000
GROUP BY rounded_profit
HAVING COUNT(*) > 5
ORDER BY rounded_profit DESC;
