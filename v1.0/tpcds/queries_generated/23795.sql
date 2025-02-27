
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        CASE 
            WHEN ws.ws_sales_price IS NOT NULL THEN 'Valid Price'
            ELSE 'Unknown'
        END AS price_status
    FROM web_sales ws
    WHERE ws.ws_sales_price > COALESCE((SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_ship_date_sk IS NOT NULL), 0)
),
AddressCounts AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate,
        COUNT(CASE WHEN cd.cd_marital_status = 'M' THEN 1 END) AS married_count,
        COUNT(*) AS total_count
    FROM customer_demographics cd
    WHERE cd.cd_credit_rating IS NOT NULL
    GROUP BY cd.cd_gender
),
InventoryDetails AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        AVG(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 0 ELSE inv.inv_quantity_on_hand END) AS avg_inventory
    FROM item i
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    ca.ca_state,
    ac.customer_count,
    cd.cd_gender,
    cd.avg_purchase_estimate,
    cd.married_count,
    inv.i_item_id,
    inv.total_inventory,
    inv.avg_inventory,
    rs.ws_order_number,
    rs.ws_sales_price,
    rs.price_status
FROM AddressCounts ac
FULL OUTER JOIN CustomerDemographics cd ON ac.customer_count > 100
JOIN InventoryDetails inv ON ac.customer_count <= inv.total_inventory
LEFT JOIN RankedSales rs ON inv.i_item_sk = rs.ws_item_sk AND rs.price_rank = 1
WHERE coef(lambda, COALESCE(ac.customer_count, 0)) > 0.5
ORDER BY ac.ca_state, cd.cd_gender, rs.ws_sales_price DESC NULLS LAST;
