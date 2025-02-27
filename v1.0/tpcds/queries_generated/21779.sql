
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn,
        ws.ws_net_profit,
        COALESCE(NULLIF(ws.ws_net_profit, 0), 1) AS profit_adjusted
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
item_sales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_profit,
        COUNT(*) AS total_orders,
        AVG(rs.profit_adjusted) AS avg_profit_adjusted
    FROM 
        ranked_sales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_item_sk
),
high_profit_items AS (
    SELECT 
        is.ws_item_sk,
        is.total_profit,
        is.total_orders,
        CASE 
            WHEN is.total_profit > 10000 THEN 'High'
            WHEN is.total_profit BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low' 
        END AS profit_category
    FROM 
        item_sales is
    WHERE 
        is.total_profit IS NOT NULL
)
SELECT 
    ii.i_item_id,
    hp.total_profit,
    hp.total_orders,
    hp.profit_category,
    DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s') AS query_timestamp
FROM 
    high_profit_items hp
JOIN 
    item ii ON hp.ws_item_sk = ii.i_item_sk
LEFT JOIN 
    WEB_PAGE wp ON wp.wp_web_page_sk = (SELECT MAX(wp2.wp_web_page_sk) FROM web_page wp2 WHERE wp2.wp_customer_sk = (SELECT MAX(c.c_customer_sk) FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL) LIMIT 1)
WHERE 
    hp.profit_category = 'High'
  AND EXISTS (
      SELECT 1
      FROM store_sales ss
      WHERE ss.ss_item_sk = hp.ws_item_sk
      AND ss.ss_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE)
  )
ORDER BY 
    hp.total_profit DESC
LIMIT 10;
