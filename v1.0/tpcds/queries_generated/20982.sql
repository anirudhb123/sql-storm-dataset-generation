
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.web_site_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS rn
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND c.c_birth_year BETWEEN 1960 AND 2000
    GROUP BY 
        ws.bill_customer_sk, ws.web_site_sk
),
SalesWithDiscount AS (
    SELECT 
        rs.bill_customer_sk,
        rs.web_site_sk,
        rs.total_sales,
        CASE 
            WHEN rs.total_sales > 1000 THEN 0.1 * rs.total_sales
            ELSE 0
        END AS discount
    FROM 
        RankedSales rs
    WHERE 
        rs.total_sales IS NOT NULL
),
SalesSummary AS (
    SELECT 
        swd.bill_customer_sk,
        swd.web_site_sk,
        swd.total_sales - swd.discount AS net_sales
    FROM 
        SalesWithDiscount swd
)
SELECT 
    ss.bill_customer_sk,
    MAX(ss.net_sales) AS highest_net_sales,
    COUNT(ss.web_site_sk) AS total_websites
FROM 
    SalesSummary ss
LEFT JOIN 
    customer_demographics cd ON ss.bill_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IS NOT NULL 
    AND ca.ca_country LIKE 'U%'
    AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status IN ('M', 'S')) 
    AND ss.highest_net_sales > (SELECT AVG(net_sales) FROM SalesSummary)
GROUP BY 
    ss.bill_customer_sk
HAVING 
    COUNT(ss.web_site_sk) < 5
ORDER BY 
    highest_net_sales DESC;
