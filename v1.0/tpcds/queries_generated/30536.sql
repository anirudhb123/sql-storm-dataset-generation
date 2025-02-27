
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        s.ss_item_sk, 
        s.ss_sold_date_sk, 
        s.ss_quantity, 
        s.ss_sales_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY s.ss_sold_date_sk) AS rank
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        s.ss_item_sk, 
        s.ss_sold_date_sk,
        s.ss_quantity,
        s.ss_sales_price
    FROM 
        sales_hierarchy sh
    JOIN 
        store s ON sh.ss_item_sk = s.ss_item_sk
    WHERE 
        s.ss_item_sk IS NOT NULL
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(s.ss_sales_price) AS total_sales,
        AVG(s.ss_quantity) AS avg_quantity,
        MAX(s.ss_sales_price) AS max_price,
        MIN(s.ss_sales_price) AS min_price
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_sales AS (
    SELECT 
        customer_sk,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
    WHERE 
        total_sales IS NOT NULL
),
latest_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        MAX(s.ss_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        MAX(s.ss_sold_date_sk) >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
)
SELECT 
    ts.customer_sk, 
    ts.total_sales, 
    ls.last_purchase_date,
    RANK() OVER (PARTITION BY ts.customer_sk ORDER BY ts.total_sales DESC) AS sales_rank,
    CASE 
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        ELSE 'Active'
    END AS customer_status,
    COALESCE(ROUND(ls.last_purchase_date / 10000.0, 2), 0) AS year_of_last_purchase
FROM 
    top_sales ts
FULL OUTER JOIN 
    latest_sales ls ON ts.customer_sk = ls.c_customer_sk
WHERE 
    ts.total_sales > 1000 OR ls.last_purchase_date IS NOT NULL
ORDER BY 
    ts.sales_rank, ls.last_purchase_date DESC;
