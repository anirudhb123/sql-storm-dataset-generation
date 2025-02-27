
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_profit) > 0
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) AS sales_rank
    FROM 
        sales_hierarchy
),
top_sales AS (
    SELECT 
        *
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
),
total_sales AS (
    SELECT 
        t.d_year,
        SUM(s.total_profit) AS overall_profit,
        COUNT(DISTINCT s.c_customer_id) AS unique_customers
    FROM 
        top_sales s
    JOIN 
        date_dim t ON t.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = s.c_customer_sk)
    GROUP BY 
        t.d_year
)
SELECT 
    t.d_year,
    total_profit,
    unique_customers,
    CASE 
        WHEN unique_customers = 0 THEN NULL
        ELSE total_profit / unique_customers
    END AS average_profit_per_customer
FROM 
    total_sales t
WHERE 
    d_year >= 2021
ORDER BY 
    d_year;
