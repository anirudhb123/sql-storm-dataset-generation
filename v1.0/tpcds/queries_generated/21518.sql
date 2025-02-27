
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_order_number) AS total_sales,
        COUNT(*) OVER (PARTITION BY ws.ws_order_number) AS quantity_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL 
        AND ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                    FROM date_dim d 
                                    WHERE d.d_year BETWEEN 2021 AND 2023)
)

SELECT 
    cs.cs_order_number,
    SUM(cs.cs_sales_price) AS catalog_total,
    COALESCE(SUM(ws.ws_sales_price), 0) AS web_total,
    COUNT(DISTINCT ws.web_site_sk) AS unique_websites,
    CASE 
        WHEN SUM(cs.cs_sales_price) > 0 THEN 'Catalog Sales'
        ELSE 'No Catalog Sales'
    END AS sales_type,
    (SELECT COUNT(*) 
     FROM customer_address ca 
     WHERE ca.ca_country = 'USA' 
       AND ca.ca_state IS NOT NULL) AS us_address_count
FROM 
    catalog_sales cs
LEFT JOIN 
    web_sales ws ON cs.cs_order_number = ws.ws_order_number
LEFT JOIN 
    RankedSales rs ON rs.ws_order_number = ws.ws_order_number AND rs.rn = 1
GROUP BY 
    cs.cs_order_number
HAVING 
    (catalog_total + web_total) > 100
    AND EXISTS (
        SELECT 1 
        FROM customer_demographics cd 
        WHERE cd.cd_dep_count > 2 
          AND cd.cd_marital_status = 'M'
          AND cd.cd_demo_sk IN (
              SELECT c.c_current_cdemo_sk 
              FROM customer c 
              WHERE c.c_email_address IS NOT NULL
          )
    )
ORDER BY 
    catalog_total DESC, 
    web_total ASC
LIMIT 100
OFFSET 10;
