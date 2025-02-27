
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_item_sk) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        SUM(p.p_cost) AS total_cost,
        COUNT(DISTINCT p.p_item_sk) AS promo_items
    FROM promotion p
    WHERE p.p_start_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND p.p_end_date_sk > (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY p.p_promo_id
),
CustomerData AS (
    SELECT 
        ca.ca_country,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country IS NOT NULL
    GROUP BY ca.ca_country
)
SELECT 
    cd.ca_country,
    cd.total_profit,
    cd.order_count,
    COALESCE(pm.total_cost, 0) AS total_promo_cost,
    CASE 
        WHEN cd.order_count > 100 THEN 'High'
        ELSE 'Low'
    END AS order_category
FROM CustomerData cd
LEFT JOIN (
    SELECT 
        c.cd_gender,
        SUM(p.total_cost) AS total_cost
    FROM Promotions p
    JOIN customer_demographics c ON p.promo_items IN (SELECT i_item_sk FROM item i WHERE i.i_item_sk = p.promo_items)
    GROUP BY c.cd_gender
) pm ON pm.cd_gender = (SELECT cd_gender FROM customer_demographics WHERE cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk = cd.ca_address_sk))
ORDER BY cd.total_profit DESC;
