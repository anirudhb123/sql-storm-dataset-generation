
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY SUM(ss.ext_sales_price) DESC) AS ranking
    FROM 
        store_sales ss
    GROUP BY 
        ss.sold_date_sk, ss.item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
top_customers AS (
    SELECT 
        ca.c_customer_sk,
        ca.c_first_name,
        ca.c_last_name,
        ca.total_spent,
        RANK() OVER (ORDER BY ca.total_spent DESC) AS customer_rank
    FROM 
        customer_analysis ca
    WHERE 
        ca.total_spent IS NOT NULL
)

SELECT 
    ca.c_customer_sk,
    ca.c_first_name,
    ca.c_last_name,
    COALESCE(sc.total_sales, 0) AS total_sales,
    ca.order_count,
    CASE 
        WHEN ca.order_count > 10 THEN 'Frequent'
        WHEN ca.order_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Infrequent'
    END AS customer_segment
FROM 
    top_customers ca
LEFT JOIN 
    (SELECT item_sk, SUM(total_sales) AS total_sales
     FROM sales_cte
     WHERE ranking <= 10
     GROUP BY item_sk) sc ON ca.c_customer_sk = sc.item_sk
WHERE 
    ca.customer_rank <= 50
ORDER BY 
    ca.total_spent DESC;
