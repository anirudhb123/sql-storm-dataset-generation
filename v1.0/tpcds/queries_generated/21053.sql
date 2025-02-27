
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_return_time_sk, 
        sr_item_sk, 
        sr_customer_sk, 
        sr_store_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM store_returns
    WHERE sr_return_quantity > 0
),
TotalSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
),
InventoryLevels AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_item_sk
),
CustomerActivity AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        COUNT(DISTINCT sr_item_sk) AS returned_items,
        MAX(CASE WHEN rnk = 1 THEN sr_returned_date_sk END) AS last_return_date
    FROM RankedReturns
    JOIN customer ON customer.c_customer_sk = RankedReturns.sr_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name
),
ReturnSummary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(distinct ca.ca_address_sk) AS unique_addresses,
        SUM(CASE WHEN ca.ca_state IS NULL THEN 1 ELSE 0 END) AS null_state_count
    FROM customer_address ca
    JOIN RankedReturns rr ON ca.ca_address_sk = rr.sr_store_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT 
    ra.c_first_name,
    ra.c_last_name,
    ta.total_sales_price,
    ta.total_orders,
    il.total_inventory,
    rs.unique_addresses,
    rs.null_state_count,
    ra.last_return_date,
    CASE 
        WHEN ra.last_return_date IS NOT NULL AND (SELECT COUNT(*) FROM RankedReturns WHERE sr_customer_sk = ra.c_customer_sk) > 5 THEN 'Frequent Returner'
        ELSE 'Occasional Returner'
    END AS returner_status
FROM CustomerActivity ra
JOIN TotalSales ta ON ra.returned_items = ta.ws_item_sk
JOIN InventoryLevels il ON ta.ws_item_sk = il.inv_item_sk
JOIN ReturnSummary rs ON rs.ca_address_sk = ra.returned_items
WHERE (ra.last_return_date < (SELECT MAX(d_date) FROM date_dim WHERE d_current_year = 'Y')
       AND ra.last_return_date >= (SELECT MIN(d_date) FROM date_dim WHERE d_current_year = 'Y' - 1))
   OR (rs.null_state_count > 0)
ORDER BY ra.c_last_name, ra.c_first_name;
