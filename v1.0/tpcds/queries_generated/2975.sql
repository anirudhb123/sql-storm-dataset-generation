
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        RankedCustomers AS c
    WHERE 
        c.rnk <= 10
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.websocket_sk
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2022)
        AND ws.ws_ship_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2022)
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    SUM(sd.ws_net_profit) AS total_profit,
    COUNT(sd.ws_item_sk) AS total_sales,
    AVG(sd.ws_quantity) AS avg_quantity_sold,
    MAX(sd.ws_net_profit) AS max_profit
FROM 
    TopCustomers AS tc
LEFT JOIN 
    SalesData AS sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name
HAVING 
    SUM(sd.ws_net_profit) > 1000
ORDER BY 
    total_profit DESC
LIMIT 50;
