
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), customer_ranks AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        ss.total_sales, 
        ss.order_count,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating 
        END AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cr.c_customer_sk,
    CONCAT(cr.c_first_name, ' ', cr.c_last_name) AS full_name,
    COALESCE(cr.total_sales, 0) AS total_sales,
    cr.order_count,
    cr.credit_rating,
    CASE 
        WHEN cr.total_sales < 1000 THEN 'Low'
        WHEN cr.total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END AS sales_category
FROM 
    customer_ranks cr
WHERE 
    cr.sales_rank <= 10
ORDER BY 
    cr.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

SELECT 
    r.r_reason_desc AS return_reason,
    COUNT(DISTINCT wr_returning_customer_sk) AS returning_customers
FROM 
    web_returns wr
JOIN 
    reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE 
    wr_returned_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
GROUP BY 
    r.r_reason_desc
HAVING 
    COUNT(DISTINCT wr_returning_customer_sk) > 5
ORDER BY 
    returning_customers DESC;
