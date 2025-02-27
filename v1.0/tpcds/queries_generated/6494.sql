
WITH sales_data AS (
    SELECT 
        ws_wholesale_cost,
        ws_list_price,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        CASE 
            WHEN ws_sales_price < 20 THEN 'Low'
            WHEN ws_sales_price BETWEEN 20 AND 50 THEN 'Medium'
            ELSE 'High'
        END AS price_category
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
customer_spend AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_sales_price * ws_quantity) AS total_spent
    FROM 
        customer c 
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
demographic_analysis AS (
    SELECT 
        cd.gender,
        SUM(cs.total_spent) AS total_spent_by_gender,
        AVG(cs.order_count) AS avg_order_count
    FROM 
        customer_spend cs
        JOIN customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.gender
)
SELECT 
    d.price_category,
    da.total_spent_by_gender,
    da.avg_order_count
FROM 
    sales_data d
    LEFT JOIN demographic_analysis da ON d.ws_net_profit > 100
ORDER BY 
    d.price_category, da.total_spent_by_gender DESC;
