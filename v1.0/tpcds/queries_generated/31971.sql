
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        cs_item_sk
)

SELECT 
    i.i_item_id,
    COALESCE(SUM(S.total_quantity), 0) AS total_quantity,
    COALESCE(SUM(S.total_sales), 0.00) AS total_sales,
    AVG(pd.p_discount_price) AS avg_discount_price,
    COUNT(DISTINCT w.web_site_id) AS website_count,
    COUNT(DISTINCT s.s_store_id) AS store_count
FROM 
    item i
LEFT JOIN 
    (SELECT 
         ws_item_sk, 
         SUM(ws_quantity) AS total_quantity, 
         SUM(ws_net_paid) AS total_sales 
     FROM 
         web_sales 
     GROUP BY 
         ws_item_sk) AS S ON i.i_item_sk = S.ws_item_sk
LEFT JOIN 
    (SELECT 
         p_item_sk, 
         (p_cost - (p_cost * 0.10)) AS p_discount_price 
     FROM 
         promotion 
     WHERE 
         p_discount_active = 'Y') AS pd ON i.i_item_sk = pd.p_item_sk
FULL OUTER JOIN 
    web_site w ON w.web_site_sk = 
        (SELECT 
             ws_web_site_sk 
         FROM 
             web_sales 
         WHERE 
             ws_item_sk = i.i_item_sk 
         LIMIT 1) 
FULL OUTER JOIN 
    store s ON s.s_store_sk = 
        (SELECT 
             ss_store_sk 
         FROM 
             store_sales 
         WHERE 
             ss_item_sk = i.i_item_sk 
         LIMIT 1)
GROUP BY 
    i.i_item_id
HAVING 
    total_sales > 1000 
    AND (total_quantity IS NOT NULL OR avg_discount_price IS NOT NULL)
ORDER BY 
    total_sales DESC, avg_discount_price ASC
LIMIT 50;
