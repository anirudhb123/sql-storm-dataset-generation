
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_sales AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        sd.total_quantity, 
        sd.total_sales
    FROM 
        sales_data sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.sales_rank <= 10
),
customer_data AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dep_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
final_report AS (
    SELECT 
        cs.c_customer_id, 
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        SUM(ts.total_sales) AS total_sales,
        COUNT(DISTINCT ts.i_item_id) AS distinct_items_purchased
    FROM 
        customer_data cs
    JOIN 
        store_sales ss ON cs.c_customer_id = ss.ss_customer_sk
    JOIN 
        top_sales ts ON ss.ss_item_sk = ts.i_item_id
    GROUP BY 
        cs.c_customer_id, cs.c_first_name, cs.c_last_name, cs.cd_gender
)
SELECT 
    fr.*, 
    CASE 
        WHEN fr.total_sales IS NULL THEN 'No Purchases'
        WHEN fr.total_sales > 1000 THEN 'High Spender'
        ELSE 'Regular Customer'
    END AS spending_category
FROM 
    final_report fr
ORDER BY 
    fr.total_sales DESC;
