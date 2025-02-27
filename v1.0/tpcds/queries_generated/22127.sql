
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws.quantity,
        ws.sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned_qty,
        COUNT(DISTINCT cr.order_number) AS unique_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
)
SELECT 
    ca.city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(COALESCE(ws.net_profit, 0)) AS total_net_profit,
    MAX(ws.sales_price) AS max_sales_price,
    COUNT(DISTINCT CASE 
        WHEN cr.returning_customer_sk IS NOT NULL THEN cr.returning_customer_sk 
        ELSE NULL 
    END) AS return_customers,
    AVG(cr.total_returned_qty) AS avg_returned_qty
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
WHERE 
    ca.state = 'CA' 
    AND (c.birth_year < 1990 OR c.birth_year IS NULL)
GROUP BY 
    ca.city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 100
ORDER BY 
    total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
