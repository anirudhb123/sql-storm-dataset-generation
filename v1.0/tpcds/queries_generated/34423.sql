
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales
    FROM
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_sales > 1000

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_sales > 1000
), AddressAggregate AS (
    SELECT
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_dep_count) AS avg_dep_count
    FROM
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_country
), SalesSummary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.total_sales,
        aa.customer_count,
        aa.avg_dep_count
    FROM
        SalesHierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_customer_sk
    LEFT JOIN 
        AddressAggregate aa ON c.c_current_addr_sk = aa.ca_address_sk
)
SELECT 
    s.c_first_name || ' ' || s.c_last_name AS customer_name,
    s.total_sales,
    s.customer_count,
    ROUND(s.avg_dep_count, 2) AS average_dependents,
    CASE
        WHEN s.total_sales > 5000 THEN 'VIP'
        WHEN s.total_sales BETWEEN 1000 AND 5000 THEN 'Regular'
        ELSE 'Low Value'
    END AS customer_class
FROM 
    SalesSummary s
WHERE
    s.customer_count IS NOT NULL
ORDER BY 
    s.total_sales DESC;
