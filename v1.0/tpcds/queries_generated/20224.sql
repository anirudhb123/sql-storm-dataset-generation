
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0 AND i.i_manufact IS NOT NULL
    GROUP BY ws.web_site_sk, ws_sold_date_sk, ws_item_sk
),
HighVolumeReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS unique_return_tickets
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_quantity) > 100
),
JoinPromotions AS (
    SELECT
        p.p_promo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_sk
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    COALESCE(SUM(hr.total_returns), 0) AS high_volume_returns,
    COALESCE(MAX(sales.total_sales), 0) AS max_sales_per_site,
    COALESCE(promo.promo_sales_count, 0) AS active_promo_sales
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN HighVolumeReturns hr ON ws.ws_item_sk = hr.sr_item_sk
LEFT JOIN RankedSales sales ON ws.ws_item_sk = sales.ws_item_sk AND ws.ws_sold_date_sk = sales.ws_sold_date_sk
LEFT JOIN JoinPromotions promo ON promo.p_promo_sk = ws.ws_promo_sk
WHERE ca.ca_state IN ('CA', 'TX') AND (c.c_birth_year IS NULL OR c.c_birth_year < 1970)
GROUP BY c.c_customer_id, ca.ca_city, promo.promo_sales_count
HAVING SUM(ws.ws_net_profit) > 5000 OR COALESCE(SUM(hr.total_returns), 0) = 0
ORDER BY total_net_profit DESC, high_volume_returns ASC NULLS LAST
LIMIT 100 OFFSET 10;
