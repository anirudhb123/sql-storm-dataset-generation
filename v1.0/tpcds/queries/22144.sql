
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        COUNT(sr_ticket_number) OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk) AS return_rank,
        SUM(sr_return_quantity) OVER (PARTITION BY sr_item_sk) AS total_return_quantity
    FROM store_returns
),
InventoryCheck AS (
    SELECT 
        i.inv_item_sk,
        COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_inventory
    FROM inventory i
    WHERE i.inv_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY i.inv_item_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(cs.cs_quantity) AS total_catalog_sales,
        SUM(ss.ss_quantity) AS total_store_sales
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    GROUP BY ws.ws_item_sk
),
Promotions AS (
    SELECT 
        p.p_item_sk,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count
    FROM promotion p
    WHERE p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY p.p_item_sk
)

SELECT 
    ci.ca_city,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    ir.total_inventory,
    pr.promo_count,
    rr.total_return_quantity,
    CASE 
        WHEN rr.total_return_quantity IS NULL THEN 'No Returns' 
        WHEN rr.total_return_quantity > ir.total_inventory THEN 'Excess Returns'
        ELSE 'Returns Within Limit'
    END AS return_status
FROM SalesSummary cs
JOIN InventoryCheck ir ON cs.ws_item_sk = ir.inv_item_sk
LEFT JOIN RankedReturns rr ON cs.ws_item_sk = rr.sr_item_sk AND rr.return_rank = 1
LEFT JOIN customer_address ci ON ci.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M'))
JOIN Promotions pr ON cs.ws_item_sk = pr.p_item_sk
WHERE (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) > 1000 
  AND ci.ca_state IS NOT NULL
ORDER BY return_status DESC, cs.total_web_sales DESC;
