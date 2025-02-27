
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ship_customer_sk,
        ws_item_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(*) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.bill_customer_sk, 
        ws.ship_customer_sk, 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_marital_status,
        ci.cd_gender,
        rs.total_profit,
        rs.total_sales
    FROM 
        customer_info ci
    JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.bill_customer_sk
    WHERE 
        rs.profit_rank <= 5
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.cd_marital_status, 'Unknown') AS marital_status,
    COALESCE(tc.cd_gender, 'Not Specified') AS gender,
    tc.total_profit,
    tc.total_sales,
    CASE 
        WHEN tc.total_sales > 20 THEN 'High Activity'
        WHEN tc.total_sales BETWEEN 10 AND 20 THEN 'Medium Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM 
    top_customers tc
ORDER BY 
    tc.total_profit DESC;

-- String expressions and calculations involving NULL logic can be seen in 
-- the COALESCE function usage and activity level categorization.
