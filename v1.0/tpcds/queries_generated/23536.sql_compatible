
WITH potential_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        d.d_date, 
        cd.cd_marital_status, 
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS rn,
        COALESCE(NULLIF(cd.cd_credit_rating, 'Fair'), 'Good') AS credit_rating_adjusted
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
    WHERE 
        d.d_year = 2023 
    AND 
        cd.cd_purchase_estimate > 5000
),
customer_activity AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
suspicious_orders AS (
    SELECT 
        sr_returning_customer_sk, 
        COUNT(sr_return_item_sk) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 5
    GROUP BY 
        sr_returning_customer_sk
),
active_customers AS (
    SELECT 
        p.c_customer_sk, 
        p.c_first_name, 
        p.c_last_name, 
        p.credit_rating_adjusted,
        COALESCE(ca.total_orders, 0) AS total_orders,
        COALESCE(ca.total_profit, 0) AS total_profit,
        COALESCE(so.return_count, 0) AS return_count
    FROM 
        potential_customers p
    LEFT JOIN 
        customer_activity ca ON p.c_customer_sk = ca.customer_sk
    LEFT JOIN 
        suspicious_orders so ON p.c_customer_sk = so.sr_returning_customer_sk
)
SELECT 
    a.c_first_name || ' ' || a.c_last_name AS full_name,
    a.credit_rating_adjusted,
    a.total_orders,
    a.total_profit,
    CASE 
        WHEN a.return_count > 0 THEN 'Suspicious Activity' 
        ELSE 'Normal Activity' 
    END AS activity_status,
    CASE 
        WHEN a.total_profit > 10000 THEN 'High Roller'
        WHEN a.total_profit BETWEEN 5000 AND 10000 THEN 'Moderate Player'
        ELSE 'Newbie'
    END AS customer_type
FROM 
    active_customers a
WHERE 
    a.total_orders > 10 
    OR (a.total_profit > 5000 AND a.total_orders > 0)
ORDER BY 
    a.total_profit DESC, a.c_last_name;
