
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(*) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ss_item_sk
    
    UNION ALL

    SELECT 
        s.ss_item_sk,
        SUM(s.ss_sales_price) + c.total_sales AS total_sales,
        COUNT(s.ss_ticket_number) + c.total_transactions AS total_transactions
    FROM store_sales s
    JOIN sales_cte c ON s.ss_item_sk = c.ss_item_sk
    WHERE s.ss_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY s.ss_item_sk, c.total_sales, c.total_transactions
)
SELECT 
    c.c_customer_id,
    SUM(s.total_sales) AS total_spent,
    MIN(s.total_transactions) AS min_transactions,
    MAX(s.total_transactions) AS max_transactions,
    AVG(s.total_sales) AS avg_spent_per_transaction
FROM customer c
JOIN (
    SELECT 
        ss_customer_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_item_sk IN (SELECT ss_item_sk FROM sales_cte)
    GROUP BY ss_customer_sk, ss_item_sk
) s ON c.c_customer_sk = s.ss_customer_sk
GROUP BY c.c_customer_id
HAVING MAX(s.total_transactions) > 5
ORDER BY total_spent DESC;
