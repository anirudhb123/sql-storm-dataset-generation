
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        AVG(CASE 
            WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_sales_price 
            ELSE 0 
        END) AS average_catalog_sales,
        AVG(CASE 
            WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_sales_price 
            ELSE 0 
        END) AS average_web_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    LEFT JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ca.ca_city,
    cs.cd_demo_sk,
    COALESCE(cs.catalog_order_count, 0) AS total_catalog_orders,
    COALESCE(cs.web_order_count, 0) AS total_web_orders,
    (COALESCE(cs.average_catalog_sales, 0) + COALESCE(cs.average_web_sales, 0)) AS total_average_sales,
    rs.total_sales AS web_site_total_sales,
    (CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Performer'
        ELSE 'Regular Performer' 
    END) AS performance_category
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    CustomerStats cs ON c.c_current_cdemo_sk = cs.cd_demo_sk
LEFT JOIN 
    RankedSales rs ON c.c_current_addr_sk = rs.web_site_sk
WHERE 
    ca.ca_state = 'CA' 
AND 
    (cs.web_order_count > 10 OR cs.catalog_order_count > 10)
ORDER BY 
    ca.ca_city, total_average_sales DESC;
