
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COALESCE(NULLIF(ca.ca_street_number, ''), 'No Number') as address_number,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'NY') OR ca.ca_city LIKE 'San%'
),
PromotionDetail AS (
    SELECT 
        p.p_promo_id,
        p.p_discount_active,
        CASE 
            WHEN p.p_discount_active = 'Y' THEN 'Active'
            ELSE 'Inactive'
        END AS promo_status,
        COUNT(DISTINCT p.p_item_sk) AS item_count
    FROM 
        promotion p
    GROUP BY 
        p.p_promo_id, p.p_discount_active
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS returns_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    s.ws_order_number,
    item.i_item_desc,
    item.i_current_price,
    total_sales_quantity.total_quantity,
    COALESCE(address.ca_city, 'Unknown') AS city,
    address.full_address, 
    promo.promo_status,
    COALESCE(return.total_returned, 0) AS total_returns,
    CASE 
        WHEN return.total_returned IS NOT NULL AND return.total_returned > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    AVG(RANKED.total_sales_price) OVER (PARTITION BY RankedSales.ws_order_number) AS avg_sales_price_per_order
FROM 
    web_sales s
JOIN 
    RankedSales AS Ranked ON s.ws_order_number = Ranked.ws_order_number 
JOIN 
    item ON s.ws_item_sk = item.i_item_sk
LEFT JOIN 
    AddressInfo AS address ON s.ws_bill_addr_sk = address.ca_address_sk
LEFT JOIN 
    PromotionDetail AS promo ON s.ws_promo_sk = promo.p_promo_id
LEFT JOIN 
    ReturnStats AS return ON s.ws_item_sk = return.sr_item_sk
WHERE 
    Ranked.price_rank = 1
    AND s.ws_quantity > 0
ORDER BY 
    s.ws_order_number, city, return_status;
