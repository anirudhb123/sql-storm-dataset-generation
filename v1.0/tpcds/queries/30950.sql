
WITH RECURSIVE sales_trends AS (
    SELECT 
        ws_sold_date_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_sold_date_sk

    UNION ALL

    SELECT 
        dt.d_date_sk,
        SUM(CASE WHEN dt.d_date_sk <= st.ws_sold_date_sk THEN st.total_orders ELSE 0 END) AS cumulative_orders,
        SUM(CASE WHEN dt.d_date_sk <= st.ws_sold_date_sk THEN st.total_profit ELSE 0 END) AS cumulative_profit
    FROM 
        date_dim dt
    JOIN 
        sales_trends st ON dt.d_date_sk > st.ws_sold_date_sk
    GROUP BY 
        dt.d_date_sk 
),
customer_info AS (
    SELECT 
        c_customer_sk, 
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY c_customer_sk) AS rn
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
highest_spenders AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer_info ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
    HAVING 
        SUM(ws.ws_net_paid) > (SELECT AVG(total_profit) FROM sales_trends)
),
summary AS (
    SELECT 
        ci.cd_gender,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
        COALESCE(SUM(sp.total_spent), 0) AS total_sales
    FROM 
        customer_info ci
    LEFT JOIN 
        highest_spenders sp ON ci.c_customer_sk = sp.c_customer_sk
    GROUP BY 
        ci.cd_gender
)
SELECT 
    s.cd_gender,
    s.customer_count,
    s.total_sales,
    COALESCE((SELECT AVG(total_sales) FROM summary), 0) AS avg_sales,
    (s.total_sales - COALESCE((SELECT AVG(total_sales) FROM summary), 0)) / NULLIF(COALESCE((SELECT AVG(total_sales) FROM summary), 0), 0) AS sales_variation
FROM 
    summary s
ORDER BY 
    s.cd_gender;
