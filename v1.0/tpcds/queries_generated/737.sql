
WITH SalesSummary AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_sales,
        AVG(ws.net_profit) AS average_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN web_site w ON ws.web_site_sk = w.web_site_sk
    WHERE ws.sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_moy IN (1, 2, 3)
    )
    GROUP BY ws.web_site_sk, ws.web_name
),

CustomerSegment AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN 'High Income'
            WHEN cd.cd_purchase_estimate > 1000 THEN 'Medium Income'
            ELSE 'Low Income'
        END AS income_segment,
        COUNT(DISTINCT ws.order_number) AS orders_count,
        SUM(ws.net_profit) AS total_profit
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, income_segment
)

SELECT 
    ss.web_name,
    ss.total_orders,
    ss.total_sales,
    ss.average_profit,
    cs.income_segment,
    cs.orders_count,
    cs.total_profit
FROM SalesSummary ss
FULL OUTER JOIN CustomerSegment cs ON ss.web_site_sk = cs.c_customer_sk
WHERE (cs.orders_count IS NOT NULL OR ss.total_orders > 0)
ORDER BY ss.total_sales DESC, cs.total_profit ASC;
