
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
),
TopItems AS (
    SELECT
        ws_item_sk,
        total_sales
    FROM SalesCTE
    WHERE rank <= 5
),
ItemDetails AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        ti.total_sales
    FROM item i
    JOIN TopItems ti ON i.i_item_sk = ti.ws_item_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COALESCE(NULLIF(ca.ca_zip, ''), 'Postal code not available') AS ca_zip
    FROM customer_address ca
)
SELECT
    id.i_item_id,
    id.i_item_desc,
    ROUND(id.i_current_price * (1 - COALESCE(MAX(pr.p_discount_active) * 0.1, 0)), 2) AS discounted_price,
    SUM(sr.sr_return_quantity) AS total_returns,
    addr.ca_city,
    addr.ca_state,
    addr.ca_zip
FROM ItemDetails id
LEFT JOIN store_returns sr ON id.i_item_sk = sr.sr_item_sk
LEFT JOIN promotion pr ON id.i_item_sk = pr.p_item_sk AND pr.p_end_date_sk > (SELECT MAX(d_date_sk) FROM date_dim)
CROSS JOIN AddressInfo addr
GROUP BY id.i_item_id, id.i_item_desc, id.i_current_price, addr.ca_city, addr.ca_state, addr.ca_zip
HAVING SUM(sr.sr_return_quantity) > 0
ORDER BY total_returns DESC;
