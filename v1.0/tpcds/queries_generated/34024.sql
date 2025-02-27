
WITH RECURSIVE total_sales AS (
    SELECT 
        ws.item_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.item_sk = i.item_sk
    WHERE 
        i.current_price IS NOT NULL
    GROUP BY 
        ws.item_sk
), 
high_value_customers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        SUM(ws.net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.customer_sk = ws.bill_customer_sk
    WHERE 
        c.birth_country IS NOT NULL
    GROUP BY 
        c.customer_sk, c.first_name, c.last_name
    HAVING 
        SUM(ws.net_paid) > 1000
), 
sales_per_day AS (
    SELECT 
        d.d_date,
        SUM(ws.net_profit) AS daily_profit
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    d.d_date,
    COALESCE(sp.daily_profit, 0) AS daily_profit,
    COALESCE(tc.total_profit, 0) AS total_profit,
    COALESCE(hv.total_spent, 0) AS high_value_customer_spending
FROM 
    date_dim d
LEFT JOIN 
    sales_per_day sp ON d.d_date = sp.d_date
LEFT JOIN 
    (SELECT 
         item_sk,
         SUM(total_profit) AS total_profit
     FROM 
         total_sales
     WHERE 
         rank <= 10
     GROUP BY 
         item_sk) tc ON tc.item_sk = (SELECT item_sk FROM total_sales)
LEFT JOIN 
    (SELECT 
         c.customer_sk,
         SUM(total_spent) AS total_spent
     FROM 
         high_value_customers c
     GROUP BY 
         c.customer_sk) hv ON hv.customer_sk = (SELECT customer_sk FROM high_value_customers)
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    d.d_date
LIMIT 100;
