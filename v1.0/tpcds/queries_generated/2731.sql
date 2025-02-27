
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        COUNT(*) AS customer_count
    FROM 
        CustomerSales
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales
    FROM 
        CustomerSales cs
    INNER JOIN 
        customer_address ca ON cs.c_customer_id = ca.ca_address_id
    WHERE 
        cs.total_sales > (SELECT avg_sales FROM AverageSales) 
        AND ca.ca_state = 'NY'
),
SalesDistribution AS (
    SELECT 
        CASE 
            WHEN total_sales < 50 THEN 'Low'
            WHEN total_sales >= 50 AND total_sales < 200 THEN 'Medium'
            ELSE 'High'
        END AS sales_band,
        COUNT(*) AS customer_count
    FROM 
        CustomerSales
    GROUP BY 
        sales_band
)
SELECT 
    s.sales_band,
    sd.customer_count,
    COALESCE(hv.total_sales, 0) AS high_value_sales
FROM 
    SalesDistribution sd
LEFT JOIN 
    (SELECT 
        sales_band, 
        SUM(total_sales) AS total_sales 
     FROM 
        HighValueCustomers 
     GROUP BY 
        sales_band) hv ON sd.sales_band = hv.sales_band
ORDER BY 
    FIELD(s.sales_band, 'Low', 'Medium', 'High');
