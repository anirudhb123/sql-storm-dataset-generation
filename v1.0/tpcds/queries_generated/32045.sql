
WITH RECURSIVE profit_analysis AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_order_number, ws_item_sk
),
top_profit AS (
    SELECT 
        pa.ws_order_number, 
        pa.ws_item_sk, 
        pa.total_profit
    FROM 
        profit_analysis pa
    WHERE 
        pa.rank = 1
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        d.d_date, 
        COALESCE(SUM(ss_ext_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON d.d_date_sk = ss.ss_sold_date_sk OR d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.total_store_sales,
    ci.total_web_sales,
    tp.total_profit
FROM 
    customer_info ci
LEFT JOIN 
    top_profit tp ON ci.c_customer_id = (SELECT cu.c_customer_id FROM customer cu WHERE cu.c_customer_sk = tp.ws_item_sk)
WHERE 
    (ci.total_store_sales > 1000 OR ci.total_web_sales > 1000)
ORDER BY 
    ci.total_store_sales DESC, ci.total_web_sales DESC
LIMIT 100;
