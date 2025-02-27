
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        NULL AS parent_id,
        0 AS level
    FROM 
        customer
    WHERE 
        c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.c_customer_sk AS parent_id,
        sh.level + 1
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
), 
return_aggregates AS (
    SELECT 
        sr_cdemo_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_cdemo_sk
),
sales_details AS (
    SELECT 
        ws_bill_cdemo_sk AS cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discounts
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
combined_data AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        COALESCE(sa.total_sales, 0) AS total_sales,
        COALESCE(ra.return_count, 0) AS total_returns,
        COALESCE(ra.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(sa.total_sales, 0) = 0 THEN NULL 
            ELSE (COALESCE(ra.total_return_amt, 0) / COALESCE(sa.total_sales, 0)) * 100 
        END AS return_rate_percentage
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        sales_details sa ON sh.c_customer_sk = sa.cdemo_sk
    LEFT JOIN 
        return_aggregates ra ON sh.c_customer_sk = ra.sr_cdemo_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    SUM(cd.total_sales) AS total_sales,
    SUM(cd.total_returns) AS total_returns,
    AVG(cd.return_rate_percentage) AS avg_return_rate_percentage
FROM 
    combined_data cd
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d2.d_date_sk) FROM web_sales ws JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk)
JOIN 
    customer c ON cd.c_customer_sk = c.c_customer_sk
GROUP BY 
    c.c_first_name, c.c_last_name, d.d_year
HAVING 
    AVG(cd.return_rate_percentage) > 10
ORDER BY 
    total_sales DESC;
