
WITH ranked_sales AS (
    SELECT 
        ss.s_store_sk,
        ss.ss_item_sk,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        RANK() OVER (PARTITION BY ss.s_store_sk ORDER BY ss.ss_ext_sales_price DESC) AS sales_rank
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
top_sales AS (
    SELECT 
        rs.s_store_sk,
        rs.ss_item_sk,
        rs.ss_sales_price,
        rs.ss_ext_sales_price
    FROM 
        ranked_sales rs
    WHERE 
        rs.sales_rank <= 10
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
final_results AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        ts.ss_item_sk,
        ts.ss_sales_price,
        ts.ss_ext_sales_price,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent IS NULL THEN 'No Purchases'
            WHEN cs.total_spent >= 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        customer_summary cs
    LEFT JOIN 
        top_sales ts ON cs.total_spent > 0
)

SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    COALESCE(f.total_spent, 0) AS total_spent,
    COALESCE(f.ss_item_sk, 'N/A') AS ss_item_sk,
    COALESCE(f.ss_sales_price, 0) AS ss_sales_price,
    COALESCE(f.ss_ext_sales_price, 0) AS ss_ext_sales_price,
    f.customer_value_segment
FROM 
    final_results f
ORDER BY 
    f.total_spent DESC, 
    f.c_last_name ASC;
