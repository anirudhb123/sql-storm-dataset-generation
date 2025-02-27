
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        ss.ss_sold_date_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        store s 
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, ss.ss_sold_date_sk
),
sales_summary AS (
    SELECT 
        sh.s_store_name,
        sh.ss_sold_date_sk,
        sh.total_sales,
        CASE 
            WHEN sh.sales_rank = 1 THEN 'Top Store'
            ELSE 'Other Store'
        END AS store_category
    FROM 
        sales_hierarchy sh
    WHERE 
        sh.total_sales > (SELECT AVG(total_sales) FROM sales_hierarchy)
),
customer_return AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        sr.sr_customer_sk
),
return_summary AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_return_amt,
        cr.total_returns,
        CASE 
            WHEN cr.total_return_amt IS NULL THEN 'No Returns'
            WHEN cr.total_return_amt > 100 THEN 'High Return'
            ELSE 'Low Return'
        END AS return_category
    FROM 
        customer_return cr
)
SELECT 
    ss.s_store_name,
    dd.d_date,
    ss.total_sales,
    rs.return_category,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    ss.total_sales - COALESCE(rs.total_return_amt, 0) AS net_sales
FROM 
    sales_summary ss
JOIN 
    date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
LEFT JOIN 
    return_summary rs ON ss.s_store_name = (SELECT s_store_name FROM store WHERE s_store_sk = rs.sr_customer_sk)
WHERE 
    dd.d_current_year = 2023
ORDER BY 
    net_sales DESC
LIMIT 10;
