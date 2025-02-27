
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
),
TotalReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amount) AS total_return_amount,
        COUNT(*) AS total_returns
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
    AVG(RS.ws_sales_price) AS average_sales_price,
    TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
    CASE 
        WHEN SUM(tr.total_return_amount) > 0 THEN 'Yes'
        ELSE 'No'
    END AS had_returns
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    TotalReturns tr ON c.c_customer_sk = tr.wr_returning_customer_sk
JOIN 
    RankedSales RS ON RS.web_site_sk = ws.ws_web_site_sk
WHERE 
    c.c_birth_year > 1980 AND c.c_birth_month = 12
GROUP BY 
    ca.ca_city, c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5 AND average_sales_price > 20
ORDER BY 
    total_sales DESC, ca.ca_city;
