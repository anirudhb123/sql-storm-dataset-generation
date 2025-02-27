
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1960 AND 2000
        AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ReturnSales AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.net_loss) AS total_returns,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
CustomerReturnMetrics AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.orders_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.return_count, 0) AS return_count
    FROM 
        CustomerSales cs
    LEFT JOIN 
        ReturnSales rs ON cs.c_customer_sk = rs.returning_customer_sk
)

SELECT 
    crm.c_customer_sk,
    crm.c_first_name,
    crm.c_last_name,
    crm.total_sales,
    crm.orders_count,
    crm.total_returns,
    crm.return_count,
    CASE 
        WHEN crm.total_sales > 1000 THEN 'High Value'
        WHEN crm.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value,
    RANK() OVER (ORDER BY crm.total_sales DESC) AS sales_rank
FROM 
    CustomerReturnMetrics crm
WHERE 
    (crm.total_returns = 0 OR crm.total_sales IS NOT NULL)
    AND crm.orders_count > 0
ORDER BY 
    customer_value, 
    sales_rank;
