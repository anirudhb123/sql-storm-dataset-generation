
WITH RECURSIVE sales_dates AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_date = '2023-01-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year
    FROM date_dim d
    JOIN sales_dates sd ON d.d_year = sd.d_year + 1 AND d.d_date > sd.d_date
),
customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
sales_by_year AS (
    SELECT sd.d_year, 
           SUM(ws.ws_net_paid) AS total_web_sales, 
           SUM(cs.cs_net_paid) AS total_catalog_sales
    FROM sales_dates sd
    LEFT JOIN web_sales ws ON sd.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON sd.d_date_sk = cs.cs_sold_date_sk
    GROUP BY sd.d_year
    HAVING SUM(ws.ws_net_paid) > 10000 OR SUM(cs.cs_net_paid) > 10000
),
top_customers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM customer_info c
    WHERE total_spent IS NOT NULL
)
SELECT cu.c_first_name,
       cu.c_last_name,
       cu.total_spent,
       sy.d_year,
       sy.total_web_sales,
       sy.total_catalog_sales
FROM top_customers cu
JOIN sales_by_year sy ON cu.rank <= 10
ORDER BY cu.total_spent DESC, sy.d_year DESC;
