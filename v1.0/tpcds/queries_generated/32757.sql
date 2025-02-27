
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        ss_store_sk

    UNION ALL

    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) + (CASE WHEN level = 1 THEN 0 ELSE total_sales END) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) + total_transactions AS total_transactions,
        level + 1
    FROM 
        sales_cte
    JOIN 
        store_sales ON sales_cte.ss_store_sk = store_sales.ss_store_sk
    WHERE 
        store_sales.ss_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        ss_store_sk
    HAVING 
        SUM(ss_ext_sales_price) > 1000
),
ranked_sales AS (
    SELECT 
        ss_store_sk,
        total_sales,
        total_transactions,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        CASE 
            WHEN total_sales > 50000 THEN 'High'
            WHEN total_sales BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        sales_cte
)
SELECT 
    a.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(s.total_sales) AS total_sales,
    AVG(s.total_transactions) AS avg_transactions,
    MAX(s.total_sales) AS max_sales,
    MIN(s.total_sales) AS min_sales,
    STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM 
    ranked_sales s
JOIN 
    store st ON s.ss_store_sk = st.s_store_sk
JOIN 
    customer c ON st.s_store_sk = c.c_current_addr_sk
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
WHERE 
    a.ca_state IS NOT NULL
    AND (s.total_sales > 20000 OR s.total_transactions > 50)
GROUP BY
    a.ca_state
ORDER BY 
    total_sales DESC 
LIMIT 10;
