
WITH RECURSIVE annual_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year >= 2010
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        a.d_year + 1,
        a.total_profit * 1.05,
        a.total_orders + FLOOR(a.total_orders * 0.1)
    FROM 
        annual_sales a
    WHERE 
        a.d_year < 2023
),
potential_customers AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT 
    a.d_year,
    p.cd_gender,
    p.cd_marital_status,
    p.cd_credit_rating,
    p.total_spent,
    CASE 
        WHEN p.total_spent > 1000 THEN 'High Value'
        WHEN p.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    ROW_NUMBER() OVER (PARTITION BY p.cd_credit_rating ORDER BY p.total_spent DESC) AS rank,
    CASE 
        WHEN p.total_spent = 0 THEN 'No Purchases'
        ELSE 'Purchases Made'
    END AS purchase_status
FROM 
    annual_sales a
JOIN 
    potential_customers p ON p.total_spent >= (SELECT AVG(total_profit) FROM annual_sales)
ORDER BY 
    a.d_year, customer_value DESC, rank
FETCH FIRST 100 ROWS ONLY;
