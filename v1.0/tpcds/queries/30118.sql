
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_profit + COALESCE(SUM(cs.cs_net_profit), 0) AS total_profit
    FROM 
        sales_hierarchy sh
        JOIN catalog_sales cs ON sh.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.total_profit
),
address_summary AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(COALESCE(c.c_birth_year, 0)) AS avg_birth_year,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_sales
    FROM 
        customer_address ca
        LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ca.ca_country
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    th.full_name,
    th.total_spent,
    ad.customer_count,
    ad.avg_birth_year,
    ad.total_sales,
    ROW_NUMBER() OVER (PARTITION BY ad.ca_country ORDER BY th.total_spent DESC) AS country_rank
FROM 
    top_customers th
    LEFT JOIN address_summary ad ON ad.customer_count > 0
WHERE 
    ad.customer_count IS NOT NULL
    AND th.total_spent > (SELECT AVG(total_spent) FROM top_customers)
ORDER BY 
    ad.total_sales DESC;
