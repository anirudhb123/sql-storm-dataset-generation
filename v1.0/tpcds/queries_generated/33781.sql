
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
address_count AS (
    SELECT 
        c.c_country,
        COUNT(DISTINCT ca.ca_address_sk) AS addr_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_country
),
high_sales AS (
    SELECT 
        s_store_sk,
        SUM(ss_ext_sales_price) AS store_total_sales
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
    HAVING 
        SUM(ss_ext_sales_price) > 10000
)
SELECT 
    ss.web_site_id,
    ss.total_sales,
    ss.order_count,
    ac.addr_count,
    hs.store_total_sales
FROM 
    sales_summary ss
LEFT JOIN 
    address_count ac ON ac.c_country = 'USA'
FULL OUTER JOIN 
    high_sales hs ON ss.web_site_sk = hs.s_store_sk
WHERE 
    ss.rank <= 5
    AND (hs.store_total_sales IS NULL OR hs.store_total_sales >= 20000)
ORDER BY 
    ss.total_sales DESC;
