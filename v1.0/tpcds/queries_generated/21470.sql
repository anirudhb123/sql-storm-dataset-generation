
WITH RankedSales AS (
    SELECT 
        ss.store_sk, 
        ss_sales_price, 
        ss_quantity, 
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY ss.net_profit DESC) as price_rank
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_dow = 1)
)
SELECT 
    s.store_id,
    s.store_name,
    COALESCE(r.sales_price_sum, 0) AS total_sales_price,
    COALESCE(r.total_quantity_sum, 0) AS total_quantity,
    COALESCE(p.promo_count, 0) AS promotional_sales_count
FROM 
    store s
LEFT JOIN (
    SELECT 
        store_sk,
        SUM(ss_sales_price) AS sales_price_sum,
        SUM(ss_quantity) AS total_quantity
    FROM 
        RankedSales
    GROUP BY 
        store_sk
) r ON s.store_sk = r.store_sk
LEFT JOIN (
    SELECT 
        ss.store_sk,
        COUNT(DISTINCT ss.promo_sk) AS promo_count
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_current_month = 'Y' AND d_holiday = 'Y')
    GROUP BY 
        ss.store_sk
) p ON s.store_sk = p.store_sk
WHERE 
    s.state IN (SELECT ca_state FROM customer_address WHERE ca_city = 'SomeCity')
ORDER BY 
    total_sales_price DESC, 
    total_quantity ASC
LIMIT 10;

WITH ItemAvailability AS (
    SELECT 
        i.i_item_id, 
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory i 
    JOIN 
        date_dim d ON d.d_date_sk = i.inv_date_sk 
    WHERE 
        d.d_year = 2023 
        AND d.d_week_seq BETWEEN 30 AND 52 
    GROUP BY 
        i.i_item_id
)

SELECT 
    ia.i_item_id,
    ia.total_inventory,
    sd.customer_id AS customer_with_max_purchases
FROM 
    ItemAvailability ia 
JOIN (
    SELECT 
        ws.bill_customer_sk, 
        COUNT(ws.ws_order_number) AS purchase_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
) sd ON ia.total_inventory > 100
WHERE 
    sd.purchase_count = (SELECT MAX(purchase_count) FROM (
        SELECT COUNT(ws_order_number) AS purchase_count 
        FROM web_sales ws 
        GROUP BY ws.bill_customer_sk
    ) AS subquery) 
ORDER BY 
    ia.total_inventory DESC
LIMIT 5;
