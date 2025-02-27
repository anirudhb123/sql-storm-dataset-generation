
WITH RECURSIVE sale_details AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
),
recent_sales AS (
    SELECT 
        cs_item_sk,
        COUNT(cs_order_number) AS order_count,
        AVG(cs_net_profit) AS average_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_dow = 5) -- Fridays
    GROUP BY 
        cs_item_sk
),
shifted_sales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(CASE WHEN ss_quantity > 10 THEN 1 ELSE 0 END) AS high_quantity_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk > (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND ss_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_item_sk
),
combined_sales AS (
    SELECT 
        sd.ws_item_sk,
        COALESCE(sd.total_quantity, 0) AS web_quantity,
        COALESCE(rs.order_count, 0) AS catalog_order_count,
        COALESCE(ss.total_sales, 0) AS store_total_sales,
        COALESCE(sd.total_net_paid, 0) AS web_net_paid,
        COALESCE(rs.average_profit, 0) AS catalog_avg_profit,
        COALESCE(ss.high_quantity_sales, 0) AS store_high_quantity_sales
    FROM 
        sale_details sd
    FULL OUTER JOIN recent_sales rs ON sd.ws_item_sk = rs.cs_item_sk
    FULL OUTER JOIN shifted_sales ss ON sd.ws_item_sk = ss.ss_item_sk
)
SELECT 
    cb.*, 
    (web_quantity * 0.2 + store_total_sales * 0.5 + catalog_order_count * 0.3) AS performance_metric,
    DECODE(web_net_paid, 0, 'No Sales', 'Sales Recorded') AS sale_status
FROM 
    combined_sales cb
WHERE 
    (web_quantity + store_total_sales) > 100 OR catalog_order_count IS NULL
ORDER BY 
    performance_metric DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
