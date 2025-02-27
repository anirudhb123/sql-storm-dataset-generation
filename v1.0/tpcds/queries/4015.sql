
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        c.c_birth_year,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_birth_year, cd.cd_gender
),
SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (PARTITION BY cs.c_birth_year ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
MostActiveCustomers AS (
    SELECT 
        sr.c_customer_sk,
        sr.total_sales,
        sr.order_count,
        sr.sales_rank,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN sr.sales_rank <= 5 THEN 'Top Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM 
        SalesRanked sr
    LEFT JOIN 
        customer_address ca ON sr.c_customer_sk = ca.ca_address_sk
    WHERE 
        sr.order_count > 10
)
SELECT 
    macc.customer_type,
    COUNT(*) AS customer_count,
    AVG(macc.total_sales) AS avg_sales,
    SUM(macc.order_count) AS total_orders,
    STRING_AGG(CONCAT(macc.c_customer_sk, ' - ', macc.total_sales), '; ') AS customer_details
FROM 
    MostActiveCustomers macc
GROUP BY 
    macc.customer_type
UNION ALL
SELECT 
    'No Sales Customers' AS customer_type,
    COUNT(*) AS customer_count,
    0 AS avg_sales,
    0 AS total_orders,
    NULL AS customer_details
FROM 
    customer c
WHERE 
    c.c_customer_sk NOT IN (SELECT DISTINCT c_customer_sk FROM web_sales)
    AND c.c_birth_year IS NOT NULL
ORDER BY 
    customer_type;
