
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_ship_date_sk BETWEEN 2500 AND 3000
),
HighProfitItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        rs.total_quantity,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    JOIN 
        item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.rnk = 1
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    COALESCE(SUM(hpi.ws_net_profit), 0) AS total_profit,
    ci.c_birth_month AS birth_month,
    CASE 
        WHEN ci.c_birth_month IS NULL THEN 'UNKNOWN'
        ELSE TO_CHAR(TO_DATE(ci.c_birth_month::text, 'MM'), 'Month')
    END AS birth_month_name,
    CASE 
        WHEN ci.c_birth_day > 15 THEN 'Second Half'
        ELSE 'First Half'
    END AS birth_half
FROM 
    customer ci
LEFT JOIN 
    HighProfitItems hpi ON ci.c_customer_sk = hpi.i_item_sk
GROUP BY 
    ci.c_customer_id, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.c_birth_month
HAVING 
    COUNT(hpi.ws_net_profit) > 5 OR total_profit > 1000
ORDER BY 
    birth_month_name
FETCH FIRST 50 ROWS ONLY;
