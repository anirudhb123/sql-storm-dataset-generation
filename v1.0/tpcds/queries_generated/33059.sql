
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ws_sold_date_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451913 AND 2451933 
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        cs_sold_date_sk
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2451913 AND 2451933 
    GROUP BY 
        cs_item_sk, cs_sold_date_sk
),
Ranked_Sales AS (
    SELECT 
        ws.web_page_sk,
        ws.ws_item_sk,
        COALESCE(SUM(c.total_quantity), 0) AS catalog_quantity,
        COALESCE(SUM(ws.total_quantity), 0) AS web_quantity,
        COALESCE(SUM(c.total_profit), 0) AS catalog_profit,
        COALESCE(SUM(ws.total_profit), 0) AS web_profit
    FROM 
        (SELECT web_page_sk, ws_item_sk FROM web_sales WHERE ws_sold_date_sk IS NOT NULL) ws
    LEFT JOIN Sales_CTE c ON ws.ws_item_sk = c.ws_item_sk
    GROUP BY 
        ws.web_page_sk, ws.ws_item_sk
),
Final_Results AS (
    SELECT 
        wp.wp_web_page_id,
        ws.sales_price,
        web_profit,
        catalog_profit,
        (web_profit - catalog_profit) AS profit_difference
    FROM 
        Ranked_Sales rs
    JOIN web_page wp ON rs.web_page_sk = wp.wp_web_page_sk
    JOIN item it ON rs.ws_item_sk = it.i_item_sk
    JOIN store s ON it.i_item_sk = s.s_store_sk
    WHERE 
        profit_difference > 0 AND 
        (web_profit IS NOT NULL OR catalog_profit IS NOT NULL)
)
SELECT 
    wp_id,
    SUM(web_profit) AS total_web_profit,
    SUM(catalog_profit) AS total_catalog_profit
FROM 
    Final_Results
GROUP BY 
    wp_id
ORDER BY 
    total_web_profit DESC
FETCH FIRST 10 ROWS ONLY;
