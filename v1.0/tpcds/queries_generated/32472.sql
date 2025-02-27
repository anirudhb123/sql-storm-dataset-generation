
WITH RECURSIVE sales_totals AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk, 
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
top_customers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.gender, 
        cs.order_count, 
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        customer_stats cs
),
recent_sales AS (
    SELECT 
        ws.ws_web_site_sk, 
        SUM(ws.ws_ext_sales_price) AS recent_sales_amount
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_date >= DATEADD(MONTH, -3, (SELECT MAX(d_date) FROM date_dim))
    GROUP BY 
        ws.ws_web_site_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.gender,
    COALESCE(Total_Spend, 0) AS Total_Spend,
    COALESCE(Order_Count, 0) AS Order_Count,
    COALESCE(recent_sales_amount, 0) AS Recent_Sales_Amount,
    CASE 
        WHEN ts.total_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Found'
    END AS Sales_Status
FROM 
    customer c
LEFT JOIN 
    top_customers cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    sales_totals ts ON cs.customer_rank = ts.rank_profit
LEFT JOIN 
    recent_sales rs ON c.c_current_addr_sk = rs.ws_web_site_sk
WHERE 
    cs.customer_rank <= 10 
    OR cs.customer_rank IS NULL
ORDER BY 
    Total_Spend DESC;
