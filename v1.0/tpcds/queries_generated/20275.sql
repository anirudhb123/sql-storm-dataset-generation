
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_by_sales
    FROM 
        web_sales
    WHERE 
        (ws_ship_date_sk BETWEEN 1 AND 365) 
        AND (ws_quantity IS NOT NULL) 
    GROUP BY 
        ws_item_sk, ws_order_number
),
SubtotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(total_net_paid) AS subtotal_net_paid
    FROM 
        RankedSales
    WHERE 
        rank_by_sales <= 3
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(ss.subtotal_net_paid, 0) AS subtotal_sales
    FROM 
        item i
    LEFT JOIN 
        SubtotalSales ss ON i.i_item_sk = ss.ws_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    CASE 
        WHEN id.subtotal_sales > 1000 THEN 'High Performer'
        WHEN id.subtotal_sales BETWEEN 500 AND 1000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    CASE 
        WHEN id.i_current_price IS NULL THEN 'No Price Available'
        ELSE TO_CHAR(id.i_current_price, 'FM$999,999.00')
    END AS formatted_price,
    (SELECT COUNT(DISTINCT cd_demo_sk) 
     FROM customer_demographics 
     WHERE cd_income_band_sk = (SELECT ib_income_band_sk 
                                 FROM income_band 
                                 WHERE ib_lower_bound <= id.subtotal_sales 
                                 AND ib_upper_bound >= id.subtotal_sales)
    ) AS income_category_count
FROM 
    ItemDetails id
WHERE 
    id.subtotal_sales IS NOT NULL
ORDER BY 
    id.subtotal_sales DESC
LIMIT 10;
