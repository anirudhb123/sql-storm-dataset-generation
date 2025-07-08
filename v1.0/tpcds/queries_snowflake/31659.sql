
WITH SalesCTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        sc.ss_store_sk,
        SUM(sc.ss_net_paid) AS total_sales,
        COUNT(DISTINCT sc.ss_ticket_number) AS total_transactions
    FROM 
        store_sales sc
    JOIN SalesCTE s ON sc.ss_store_sk = s.ss_store_sk
    WHERE 
        sc.ss_sold_date_sk > '2022-03-01'
    GROUP BY 
        sc.ss_store_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS web_sales,
        COUNT(ws.ws_order_number) AS web_order_count,
        d.d_year AS sales_year
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, d.d_year
),
AddressSales AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(cs.cs_net_paid) AS catalog_sales
    FROM 
        catalog_sales cs
    JOIN 
        customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
)
SELECT 
    sales.ca_city,
    COALESCE(ws.web_sales, 0) AS web_sales,
    COALESCE(cs.catalog_sales, 0) AS catalog_sales,
    sc.total_sales AS store_sales,
    (COALESCE(ws.web_sales, 0) + COALESCE(cs.catalog_sales, 0) + COALESCE(sc.total_sales, 0)) AS total_sales_combined
FROM 
    (SELECT 
        ca.ca_city,
        SUM(ws.ws_net_paid) AS web_sales
     FROM 
        web_sales ws
     JOIN 
        customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
     GROUP BY 
        ca.ca_city) sales
LEFT JOIN 
    CustomerSales ws ON ws.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE ws.web_order_count > 0)
LEFT JOIN 
    AddressSales cs ON cs.ca_city = sales.ca_city
LEFT JOIN 
    SalesCTE sc ON sc.ss_store_sk = (SELECT s.s_store_sk FROM store s LIMIT 1)
WHERE 
    (COALESCE(sc.total_sales, 0) > 100000 OR COALESCE(ws.web_sales, 0) > 50000)
ORDER BY 
    total_sales_combined DESC
LIMIT 10;
