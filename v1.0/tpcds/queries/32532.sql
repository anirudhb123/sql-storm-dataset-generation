
WITH RECURSIVE sales_depth AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        1 AS depth
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        sd.depth + 1
    FROM 
        catalog_sales cs
    JOIN 
        sales_depth sd ON cs.cs_order_number = sd.ws_order_number
    WHERE 
        sd.depth < 3
),
total_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_net_profit) AS total_profit,
        COUNT(DISTINCT sd.ws_order_number) AS order_count
    FROM 
        sales_depth sd
    GROUP BY 
        sd.ws_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
        CASE 
            WHEN COALESCE(SUM(ss.ss_net_profit), 0) + COALESCE(SUM(ws.ws_net_profit), 0) > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
final_output AS (
    SELECT 
        ca.c_customer_sk,
        ca.c_first_name,
        ca.c_last_name,
        ca.cd_gender,
        ca.total_store_sales,
        ca.total_web_sales,
        ca.customer_value,
        ts.total_profit,
        ts.order_count
    FROM 
        customer_analysis ca
    LEFT JOIN 
        total_sales ts ON ca.c_customer_sk = ts.ws_item_sk
)

SELECT 
    fo.c_customer_sk,
    fo.c_first_name,
    fo.c_last_name,
    fo.cd_gender,
    COALESCE(fo.total_store_sales, 0) AS total_store_sales,
    COALESCE(fo.total_web_sales, 0) AS total_web_sales,
    fo.customer_value,
    COALESCE(fo.total_profit, 0) AS total_profit,
    fo.order_count
FROM 
    final_output fo
WHERE 
    fo.customer_value = 'High Value'
ORDER BY 
    fo.total_profit DESC
LIMIT 10;
