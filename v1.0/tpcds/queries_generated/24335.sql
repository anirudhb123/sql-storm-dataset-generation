
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_number, ca_street_name, ca_city, ca_state,
           CASE WHEN ca_city IS NULL THEN 'UNKNOWN CITY' ELSE ca_city END AS formatted_city
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_address_id, a.ca_street_number, a.ca_street_name, a.ca_city, a.ca_state,
           'CITY LOADED' 
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_address_sk = ah.ca_address_sk + 1
    WHERE a.ca_state IS NOT NULL
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
AggregatedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        total_quantity,
        total_profit,
        unique_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY total_profit DESC) AS rank
    FROM SalesData
    WHERE total_profit > 0
),
PromotionSummary AS (
    SELECT 
        p_promo_id,
        COUNT(cs_order_number) AS promo_impact,
        SUM(cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY p_promo_id
)
SELECT 
    ah.formatted_city,
    CONCAT('Promo: ', ps.promo_impact) AS promo_summary,
    SUM(a.total_quantity) AS quantity_sold,
    SUM(a.total_profit) AS total_profit,
    AVG(a.total_profit) FILTER (WHERE a.unique_orders > 5) AS avg_profit_per_order,
    CASE 
        WHEN SUM(a.total_profit) IS NULL THEN 'NO PROFIT'
        WHEN SUM(a.total_profit) > 1000 THEN 'HIGH PROFIT'
        ELSE 'LOW PROFIT'
    END AS profit_category,
    COALESCE(MAX(a.rank), 0) AS max_rank
FROM AddressHierarchy ah
LEFT JOIN AggregatedSales a ON ah.ca_address_sk = a.ws_item_sk
LEFT JOIN PromotionSummary ps ON a.ws_item_sk IN (SELECT cs_item_sk FROM catalog_sales)
GROUP BY ah.formatted_city, ps.promo_impact
HAVING COUNT(a.total_quantity) > 10
ORDER BY total_profit DESC NULLS LAST;
