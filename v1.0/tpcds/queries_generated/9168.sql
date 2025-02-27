
WITH ranked_sales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                             AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ss_store_sk, ss_item_sk
),
store_info AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        s_city, 
        s_state, 
        s_country
    FROM 
        store
),
customer_info AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        cd_gender, 
        cd_marital_status
    FROM 
        customer 
        JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
)
SELECT 
    si.s_store_name, 
    si.s_city, 
    si.s_state, 
    si.s_country,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    SUM(rs.total_quantity) AS total_quantity_sold,
    SUM(rs.total_net_paid) AS total_revenue,
    MAX(rs.sales_rank) AS highest_sales_rank
FROM 
    ranked_sales rs
JOIN 
    store_info si ON rs.ss_store_sk = si.s_store_sk
JOIN 
    customer_info ci ON rs.ss_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_ship_customer_sk = ci.c_customer_sk)
WHERE 
    rs.sales_rank <= 10 
GROUP BY 
    si.s_store_sk, si.s_store_name, si.s_city, si.s_state, si.s_country
ORDER BY 
    total_revenue DESC
LIMIT 100;
