
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CTE_Returned_Sales AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returned_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
CTE_Web_Sales_Rank AS (
    SELECT 
        customer_sk, 
        ROW_NUMBER() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank
    FROM 
        CTE_Customer_Sales
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    coalesce(ws.total_web_sales, 0) AS total_web_sales,
    coalesce(rs.total_returned_amount, 0) AS total_returned_amount,
    CASE 
        WHEN ws.total_web_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    CASE 
        WHEN ws.total_web_sales > 1000 THEN 'High Value'
        ELSE 'Regular Value'
    END AS customer_value
FROM 
    CTE_Customer_Sales ws
FULL OUTER JOIN 
    CTE_Returned_Sales rs ON ws.c_customer_sk = rs.returning_customer_sk
JOIN 
    CTE_Web_Sales_Rank r ON ws.c_customer_sk = r.customer_sk
WHERE 
    (rs.total_returned_amount IS NULL OR rs.total_returned_amount < 1000)
    AND (ws.total_web_sales > 500 OR ws.total_web_sales IS NULL)
ORDER BY 
    r.web_sales_rank;
