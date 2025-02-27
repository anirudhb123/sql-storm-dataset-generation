
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_ext_sales_price) > 1000
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
    HAVING 
        SUM(cs_ext_sales_price) > 1000
)
SELECT 
    ca.city,
    ca.state,
    SUM(S.total_sales) AS total_sales,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    AVG(cd.cd_dep_count) AS avg_dependents,
    MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
FROM 
    SalesCTE S
JOIN 
    item i ON S.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer c ON c.c_customer_sk = (CASE 
                                          WHEN S.sales_rank = 1 THEN c.c_customer_sk 
                                          ELSE NULL 
                                      END)
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.city IS NOT NULL
GROUP BY 
    ca.city, ca.state
HAVING 
    SUM(S.total_sales) > 50000
ORDER BY 
    total_sales DESC
LIMIT 10;
