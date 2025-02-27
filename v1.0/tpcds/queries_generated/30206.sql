
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        dep.customer_sk,
        dep.first_name,
        dep.last_name,
        ch.level + 1
    FROM 
        customer dep
    JOIN 
        CustomerHierarchy ch ON dep.current_cdemo_sk = ch.customer_sk
),
SalesData AS (
    SELECT 
        w.ws_item_sk,
        SUM(w.ws_quantity) AS total_quantity,
        SUM(w.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY w.ws_item_sk ORDER BY SUM(w.ws_net_profit) DESC) AS rank
    FROM 
        web_sales w
    JOIN 
        item i ON w.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 AND 
        i.i_rec_start_date <= CURDATE() AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURDATE())
    GROUP BY 
        w.ws_item_sk
)
SELECT 
    ch.first_name,
    ch.last_name,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_profit, 0) AS total_profit,
    CASE 
        WHEN sd.rank = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_status
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    SalesData sd ON ch.customer_sk = sd.ws_item_sk
WHERE 
    ch.level = (SELECT MAX(level) FROM CustomerHierarchy)
ORDER BY 
    ch.last_name, ch.first_name
FETCH FIRST 10 ROWS ONLY;
