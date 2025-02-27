
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price > (
            SELECT AVG(ws1.ws_sales_price)
            FROM web_sales ws1
            WHERE ws1.ws_sold_date_sk >= 2450000
        )
),
StoreDetails AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        COUNT(DISTINCT sr.sr_item_sk) AS returns_count,
        SUM(sr.sr_return_amt) AS total_returns
    FROM
        store s
    LEFT JOIN store_returns sr ON s.s_store_sk = sr.s_store_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country
),
FilteredInventory AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
    HAVING
        SUM(inv.inv_quantity_on_hand) > 50
)
SELECT
    cd.cd_gender,
    ca.ca_city,
    ca.ca_state,
    SUM(RS.ws_ext_sales_price) AS total_sales,
    COALESCE(SD.returns_count, 0) AS total_returns,
    SUM(FI.total_quantity) AS total_inventory
FROM
    customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN RankedSales RS ON c.c_customer_sk = RS.ws_order_number
LEFT JOIN StoreDetails SD ON ca.ca_city = SD.s_city AND ca.ca_state = SD.s_state
LEFT JOIN FilteredInventory FI ON RS.ws_item_sk = FI.inv_item_sk
WHERE
    cd.cd_marital_status = 'M'
    AND (ca.ca_country IS NULL OR ca.ca_country <> 'USA')
    AND EXISTS (
        SELECT 1
        FROM store s
        WHERE s.s_store_id LIKE '%Store%'
          AND s.s_state IN ('CA', 'NY')
    )
GROUP BY
    cd.cd_gender,
    ca.ca_city,
    ca.ca_state
ORDER BY
    total_sales DESC,
    total_returns ASC;
