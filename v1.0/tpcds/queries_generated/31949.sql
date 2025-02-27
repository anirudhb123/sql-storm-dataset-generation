
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ss.ss_net_paid, 0) AS total_spent,
        1 AS level
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ss.ss_net_paid, 0) + COALESCE(parent.total_spent, 0) AS total_spent,
        parent.level + 1
    FROM customer c
    JOIN SalesHierarchy parent ON c.c_customer_sk = parent.c_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
)

SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_quantity) AS total_items_sold,
    AVG(ss.ss_net_paid) AS avg_spent_per_transaction,
    COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
    RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS spending_rank,
    CASE 
        WHEN SUM(ss.ss_net_paid) > 1000 THEN 'High Spender'
        WHEN SUM(ss.ss_net_paid) BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM customer c
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F' 
   OR cd.cd_marital_status = 'S'
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING COUNT(DISTINCT ss.ss_ticket_number) > 2
ORDER BY AVG(ss.ss_net_paid) DESC
LIMIT 10;

SELECT * 
FROM (SELECT 
          customer.c_customer_sk,
          customer.c_first_name,
          customer.c_last_name,
          COALESCE(catalog_sales.cs_net_paid, 0) AS total_net_paid_catalog,
          COALESCE(web_sales.ws_net_paid, 0) AS total_net_paid_web,
          (COALESCE(catalog_sales.cs_net_paid, 0) + COALESCE(web_sales.ws_net_paid, 0)) AS total_net_paid
      FROM customer
      LEFT JOIN catalog_sales ON customer.c_customer_sk = catalog_sales.cs_bill_customer_sk
      LEFT JOIN web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk) AS sales_summary
WHERE total_net_paid IS NOT NULL
ORDER BY total_net_paid DESC;

SELECT 
    d.d_year AS year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_sales_price - ss.ss_wholesale_cost) AS total_gross_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_net_profit) OVER (PARTITION BY d.d_year) AS avg_profit_per_transaction
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2021 AND 2022
GROUP BY d.d_year
ORDER BY d.d_year;

SELECT DISTINCT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name,
    (SELECT COUNT(DISTINCT wr.web_page_sk) 
     FROM web_sales ws 
     INNER JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number 
     WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS num_web_returns 
FROM customer c 
WHERE c.c_birth_year < (
    SELECT AVG(c_birth_year) FROM customer) 
ORDER BY num_web_returns DESC;
