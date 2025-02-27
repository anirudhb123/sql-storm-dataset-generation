
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ship_customer_sk,
        SUM(ws.net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_paid) DESC) as sale_rank,
        COUNT(DISTINCT ws.web_page_sk) AS page_views
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND c.c_birth_month > 0 
        AND (c.c_first_shipto_date_sk IS NULL OR c.c_first_sales_date_sk > 20220101)
    GROUP BY 
        ws.bill_customer_sk, 
        ws.ship_customer_sk
), 
HighValueCustomers AS (
    SELECT 
        bill_customer_sk,
        ship_customer_sk,
        total_sales,
        sale_rank,
        page_views,
        CASE 
            WHEN total_sales > (SELECT AVG(total_sales) FROM RankedSales) THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_type
    FROM 
        RankedSales
    WHERE 
        sale_rank <= 10
)
SELECT 
    c.c_customer_id,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    hvc.total_sales,
    hvc.page_views,
    hvc.customer_type,
    STRING_AGG(DISTINCT i.i_product_name) AS purchased_products
FROM 
    customer c
JOIN 
    HighValueCustomers hvc ON c.c_customer_sk = hvc.bill_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON ws.bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY 
    c.c_customer_id, 
    ca.ca_city, 
    hvc.total_sales, 
    hvc.page_views, 
    hvc.customer_type
HAVING 
    COUNT(ws.ws_item_sk) > 1
ORDER BY 
    hvc.total_sales DESC,
    hvc.page_views DESC
LIMIT 100
UNION
SELECT 
    'Aggregate' AS c_customer_id,
    NULL AS city,
    SUM(total_sales) AS total_sales,
    SUM(page_views) AS page_views,
    'Aggregate' AS customer_type,
    NULL AS purchased_products
FROM 
    HighValueCustomers
WHERE 
    total_sales IS NOT NULL;
