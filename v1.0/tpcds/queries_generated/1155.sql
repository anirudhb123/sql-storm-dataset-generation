
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_sk
),
TopWebsites AS (
    SELECT web_site_sk
    FROM RankedSales
    WHERE profit_rank <= 5
)
SELECT
    wa.w_warehouse_id,
    ra.ca_city,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
    COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales_amount,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
    SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_return_quantity ELSE 0 END) AS total_return_quantity,
    MAX(ws_total.total_profit) AS max_website_profit
FROM warehouse wa
LEFT JOIN store s ON s.s_store_sk = wa.w_warehouse_sk
LEFT JOIN customer_address ra ON ra.ca_address_sk = s.s_closed_date_sk
LEFT JOIN catalog_sales cs ON cs.cs_call_center_sk IN (
    SELECT DISTINCT cc.cc_call_center_sk
    FROM call_center cc
    WHERE cc.cc_mkt_class = 'Affiliate'
)
LEFT JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
JOIN (
    SELECT web_site_sk, total_profit
    FROM RankedSales
    WHERE web_site_sk IN (SELECT web_site_sk FROM TopWebsites)
) ws_total ON ws_total.web_site_sk = s.s_store_sk
GROUP BY wa.w_warehouse_id, ra.ca_city
HAVING COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY total_catalog_sales_amount DESC
LIMIT 15;
