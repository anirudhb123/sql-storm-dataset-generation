
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_last_name) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status
    FROM RankedSales rs
    JOIN CustomerInfo ci ON ci.rn = 1
    WHERE rs.rn = 1
)
SELECT 
    ts.ws_order_number,
    ts.c_first_name,
    ts.c_last_name,
    ts.ws_sales_price,
    SUM(CASE 
        WHEN ts.cd_gender = 'M' THEN 1 
        ELSE 0 
    END) AS male_count,
    SUM(CASE 
        WHEN ts.cd_gender = 'F' THEN 1 
        ELSE 0 
    END) AS female_count,
    AVG(ts.ws_sales_price) OVER (PARTITION BY ts.c_first_name ORDER BY ts.ws_order_number) AS avg_sales_price
FROM TopSales ts
LEFT JOIN store_returns sr ON ts.ws_item_sk = sr.sr_item_sk AND ts.ws_order_number = sr.sr_ticket_number
WHERE sr.sr_return_quantity IS NULL
GROUP BY ts.ws_order_number, ts.c_first_name, ts.c_last_name, ts.ws_sales_price
HAVING SUM(ts.ws_sales_price) > 1000
ORDER BY SUM(ts.ws_sales_price) DESC;
