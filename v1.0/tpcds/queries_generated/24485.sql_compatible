
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_net_profit < (SELECT AVG(ws_net_profit) FROM web_sales) 
),
AddressDetails AS (
    SELECT 
        ca_address_id, 
        ca_city, 
        ca_state,
        COUNT(ca_address_id) OVER (PARTITION BY ca_city, ca_state) AS city_state_count
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
ItemPromotions AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws_item_sk) AS promo_item_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
),
TotalReturns AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
)

SELECT 
    s.s_store_name,
    rd.ws_item_sk,
    rd.rn,
    COALESCE(ad.ca_city, 'Unknown') AS city,
    COALESCE(ad.ca_state, 'Unknown') AS state,
    ip.promo_item_count,
    tr.total_return_quantity,
    SUM(rd.ws_net_profit) AS total_net_profit
FROM 
    RankedSales rd
LEFT JOIN 
    store s ON s.s_store_sk = (
        SELECT ss_store_sk 
        FROM store_sales ss 
        WHERE ss_item_sk = rd.ws_item_sk 
        LIMIT 1
    ) 
LEFT JOIN 
    AddressDetails ad ON ad.ca_address_id = (
        SELECT ca_address_id 
        FROM customer_address 
        WHERE ca_address_sk = (
            SELECT c.c_current_addr_sk 
            FROM customer c 
            WHERE c.c_customer_sk = rd.ws_order_number
        ) 
        LIMIT 1
    )
LEFT JOIN 
    ItemPromotions ip ON ip.promo_item_count > 5 
LEFT JOIN 
    TotalReturns tr ON tr.sr_returned_date_sk = rd.ws_order_number
WHERE 
    rd.rn = 1
    AND (tr.total_return_quantity IS NULL OR tr.total_return_quantity < 10) 
GROUP BY 
    s.s_store_name, 
    rd.ws_item_sk, 
    rd.rn, 
    ad.ca_city, 
    ad.ca_state, 
    ip.promo_item_count, 
    tr.total_return_quantity
ORDER BY 
    total_net_profit DESC
LIMIT 100;
