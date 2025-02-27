
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        * 
    FROM 
        ranked_customers 
    WHERE 
        customer_rank <= 10
),
in_store_sales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
combined_sales AS (
    SELECT 
        i.i_item_id,
        COALESCE(ws.ws_net_paid, 0) AS online_sales,
        COALESCE(is.total_store_sales, 0) AS in_store_sales
    FROM 
        item i
    LEFT JOIN 
        (SELECT 
            ws_item_sk, SUM(ws_net_paid) AS ws_net_paid
         FROM 
            web_sales
         GROUP BY 
            ws_item_sk) ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        in_store_sales is ON i.i_item_sk = is.ss_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    cs.i_item_id,
    cs.online_sales,
    cs.in_store_sales,
    (cs.online_sales + cs.in_store_sales) AS total_sales,
    (cs.online_sales / NULLIF(cs.online_sales + cs.in_store_sales, 0)) AS online_sales_percentage
FROM 
    top_customers tc
JOIN 
    combined_sales cs ON tc.c_customer_sk = cs.i_item_id
ORDER BY 
    total_sales DESC
LIMIT 20;
