
WITH RECURSIVE sales_series AS (
    SELECT 
        cs_sold_date_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY cs_sold_date_sk) AS row_num
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk
    HAVING 
        SUM(cs_net_profit) > 1000
    UNION ALL
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY ws_sold_date_sk) AS row_num
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
    GROUP BY 
        ws_sold_date_sk
    HAVING 
        SUM(ws_net_profit) > 500
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(cs.cs_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_marital_status, cd.cd_gender
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ci.order_count,
        ci.total_spent,
        DENSE_RANK() OVER (ORDER BY ci.total_spent DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        customer_info ci ON c.c_customer_sk = ci.c_customer_sk
    WHERE 
        ci.order_count > 5
)
SELECT 
    s.sales_date,
    COALESCE(ss.total_profit, 0) AS sales_profit,
    COALESCE(tc.order_count, 0) AS top_customer_orders,
    tc.c_first_name,
    tc.c_last_name,
    tc.spending_rank
FROM 
    (SELECT DISTINCT cs_sold_date_sk AS sales_date FROM catalog_sales) s
LEFT JOIN 
    sales_series ss ON s.sales_date = ss.cs_sold_date_sk
LEFT JOIN 
    top_customers tc ON ss.row_num = tc.spending_rank
WHERE 
    s.sales_date BETWEEN (SELECT MIN(d_date) FROM date_dim) AND (SELECT MAX(d_date) FROM date_dim)
ORDER BY 
    sales_profit DESC, top_customer_orders DESC;
