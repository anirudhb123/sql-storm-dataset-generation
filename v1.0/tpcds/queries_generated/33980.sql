
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        1 AS level
    FROM
        store s
    JOIN
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE
        ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)

    UNION ALL
    
    SELECT
        sh.s_store_sk,
        sh.s_store_name,
        sh.s_state,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        sh.level + 1
    FROM
        sales_hierarchy sh
    JOIN
        store_sales ss ON sh.ss_ticket_number = ss.ss_ticket_number
    WHERE
        sh.level < 3
),
monthly_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers
    FROM
        store_sales s
    JOIN
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
),
aggregated_sales AS (
    SELECT
        d.d_month_seq,
        COALESCE(m.total_sales, 0) AS total_sales,
        m.total_transactions,
        m.unique_customers,
        RANK() OVER (ORDER BY COALESCE(m.total_sales, 0) DESC) AS sales_rank
    FROM
        date_dim d
    LEFT JOIN 
        monthly_sales m ON d.d_year = 2023 AND d.d_month_seq = m.d_month_seq
)

SELECT
    a.d_month_seq,
    a.total_sales,
    a.total_transactions,
    a.unique_customers,
    a.sales_rank,
    CASE 
        WHEN a.total_sales > 1000000 THEN 'High'
        WHEN a.total_sales > 500000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM
    aggregated_sales a
WHERE
    a.total_sales > (
        SELECT AVG(total_sales) FROM aggregated_sales
    )
ORDER BY
    a.sales_rank;

```
