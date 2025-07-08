
WITH AddressCounts AS (
    SELECT ca_state, COUNT(*) AS state_count,
           LISTAGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_city, ', ', ca_zip), '; ') WITHIN GROUP (ORDER BY ca_street_number) AS full_address
    FROM customer_address
    GROUP BY ca_state
),
PromotionsData AS (
    SELECT 
        p.p_promo_name AS promo_name, 
        p.p_promo_id, 
        COUNT(cs.cs_order_number) AS promo_usage_count
    FROM promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_name, p.p_promo_id
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT 
    ac.ca_state, 
    ac.state_count, 
    ac.full_address,
    pd.promo_name,
    pd.promo_usage_count,
    ss.total_sales,
    ss.avg_sales_price
FROM AddressCounts ac
LEFT JOIN PromotionsData pd ON ac.state_count > 100
LEFT JOIN SalesSummary ss ON ss.total_sales > 10000
ORDER BY ac.state_count DESC, pd.promo_usage_count DESC;
