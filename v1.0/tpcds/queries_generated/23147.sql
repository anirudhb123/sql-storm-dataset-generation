
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as rank
    FROM web_sales ws
    WHERE ws.ws_sales_price > (
        SELECT AVG(ws_sub.ws_sales_price)
        FROM web_sales ws_sub
        WHERE ws_sub.ws_item_sk = ws.ws_item_sk
    )
),
inventory_summary AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
detailed_returns AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
    GROUP BY sr.sr_item_sk
),
item_statistics AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        ISNULL(r.total_returned, 0) AS total_returned,
        ISNULL(r.total_return_amt, 0) AS total_return_amt,
        ISNULL(s.total_quantity_on_hand, 0) AS total_quantity_on_hand,
        COALESCE(s.total_quantity_on_hand, 0) - COALESCE(r.total_returned, 0) AS net_quantity
    FROM item i
    LEFT JOIN detailed_returns r ON i.i_item_sk = r.sr_item_sk
    LEFT JOIN inventory_summary s ON i.i_item_sk = s.inv_item_sk
),
final_selection AS (
    SELECT 
        it.i_item_sk,
        it.i_item_desc,
        it.total_returned,
        it.total_return_amt,
        it.total_quantity_on_hand,
        it.net_quantity,
        ROW_NUMBER() OVER (ORDER BY it.total_return_amt DESC) as return_rank
    FROM item_statistics it
    WHERE it.net_quantity > 0
)
SELECT
    fs.i_item_sk,
    fs.i_item_desc,
    fs.total_returned,
    fs.total_return_amt,
    fs.total_quantity_on_hand,
    fs.net_quantity,
    (CASE 
        WHEN fs.total_return_amt > 1000 THEN 'High Return'
        WHEN fs.net_quantity < 50 AND fs.total_return_amt > 500 THEN 'Risk Item'
        ELSE 'Normal' 
    END) AS return_status
FROM final_selection fs
WHERE fs.return_rank <= 10
ORDER BY fs.total_return_amt DESC
UNION ALL
SELECT 
    ca.ca_address_sk,
    CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city) AS full_address,
    NULL AS total_returned,
    NULL AS total_return_amt,
    NULL AS total_quantity_on_hand,
    NULL AS net_quantity,
    'Address' AS return_status
FROM customer_address ca
WHERE ca.ca_country = 'Unknown'
ORDER BY total_return_amt DESC NULLS LAST;
