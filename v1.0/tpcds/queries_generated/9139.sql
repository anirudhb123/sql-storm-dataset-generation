
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.net_profit) as total_net_profit,
        COUNT(DISTINCT ws.order_number) as total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) as profit_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.web_site_sk, ws.web_name
), customer_stats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_spent,
        MAX(rs.total_net_profit) as max_website_profit
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
    JOIN
        ranked_sales rs ON ws.web_site_sk = rs.web_site_sk
    GROUP BY
        c.c_customer_sk
), analytics AS (
    SELECT
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent < 1000 THEN 'Low Spender'
            WHEN cs.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Spender'
            ELSE 'High Spender'
        END AS spending_category
    FROM
        customer_stats cs
)
SELECT
    a.spending_category,
    COUNT(*) AS number_of_customers,
    AVG(a.total_spent) AS average_spent,
    MIN(a.total_orders) AS min_orders,
    MAX(a.total_orders) AS max_orders
FROM
    analytics a
GROUP BY
    a.spending_category
ORDER BY
    FIELD(a.spending_category, 'Low Spender', 'Medium Spender', 'High Spender');
