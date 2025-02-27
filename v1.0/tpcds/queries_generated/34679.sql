
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_item_desc,
        i_current_price,
        i_brand,
        1 AS level
    FROM item
    WHERE i_current_price > 100
    UNION ALL
    SELECT 
        i.item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price * 0.9,
        ih.i_brand,
        ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk + 1
),
SalesData AS (
    SELECT 
        w.ws_item_sk,
        SUM(CASE 
            WHEN w.ws_net_profit IS NULL THEN 0 
            ELSE w.ws_net_profit 
        END) AS total_net_profit,
        COUNT(DISTINCT w.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY w.ws_item_sk ORDER BY SUM(w.ws_net_profit) DESC) AS rn
    FROM web_sales w
    JOIN ItemHierarchy ih ON w.ws_item_sk = ih.i_item_sk
    GROUP BY w.ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN c.c_birth_month = 12 THEN 'Holiday Shopper'
            ELSE 'Regular Shopper' 
        END AS shopper_type,
        SUM(sd.total_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_birth_month
)
SELECT 
    cs.shopper_type,
    COUNT(cs.c_customer_sk) AS customer_count,
    AVG(cs.total_profit) AS average_profit
FROM CustomerSales cs
GROUP BY cs.shopper_type
ORDER BY customer_count DESC
LIMIT 10;
