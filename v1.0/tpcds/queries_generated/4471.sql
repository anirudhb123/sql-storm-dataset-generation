
WITH SalesData AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_ext_sales_price, 
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0 
        AND EXISTS (
            SELECT 1 
            FROM item i 
            WHERE i.i_item_sk = ws.ws_item_sk AND i.i_current_price IS NOT NULL
        )
),
HighProfitItems AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_quantity,
        sd.ws_ext_sales_price,
        sd.ws_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.rnk = 1
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_marital_status,
    ci.cd_gender,
    COUNT(DISTINCT hpi.ws_order_number) AS total_orders,
    SUM(hpi.ws_ext_sales_price) AS total_sales,
    AVG(hpi.ws_net_profit) AS avg_net_profit
FROM 
    HighProfitItems hpi
JOIN 
    CustomerInfo ci ON hpi.ws_order_number IN (
        SELECT ws_order_number 
        FROM web_sales 
        WHERE ws_item_sk IN (SELECT ws_item_sk FROM HighProfitItems)
    )
GROUP BY 
    ci.c_customer_id, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_marital_status, 
    ci.cd_gender
HAVING 
    total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;
