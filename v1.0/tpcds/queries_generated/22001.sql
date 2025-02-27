
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_gender
),
HighSpenders AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS row_num
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales) 
)
SELECT 
    c.c_customer_id,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(ws.ws_ext_discount_amt), 0) AS total_discounts,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_type,
    DENSE_RANK() OVER (ORDER BY COALESCE(SUM(sr.sr_return_quantity), 0) DESC) AS return_rank
FROM 
    customer c
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    HighSpenders hs ON c.c_customer_id = hs.c_customer_id
GROUP BY 
    c.c_customer_id, cs.total_sales
HAVING 
    (total_returns > 0 OR total_discounts > 0) 
    AND (customer_type IS NOT NULL)
ORDER BY 
    return_rank, total_returns DESC
LIMIT 10;
