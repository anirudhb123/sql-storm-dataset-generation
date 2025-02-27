
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    GROUP BY ws.web_site_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COALESCE(SUM(CASE WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_quantity END), 0) AS shipped_quantity,
        COALESCE(SUM(CASE WHEN ws.ws_ship_date_sk IS NULL THEN ws.ws_quantity END), 0) AS pending_quantity
    FROM web_sales ws
    JOIN RankedSales rs ON ws.ws_web_site_sk = rs.web_site_sk
    GROUP BY ws.ws_web_site_sk
)
SELECT 
    ss.ws_web_site_sk,
    ss.total_quantity,
    ss.avg_net_profit,
    ss.shipped_quantity,
    ss.pending_quantity,
    CASE 
        WHEN ss.total_quantity > 100 THEN 'High Sales'
        WHEN ss.total_quantity BETWEEN 50 AND 100 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_level
FROM SalesSummary ss
FULL OUTER JOIN web_site w ON ss.ws_web_site_sk = w.web_site_sk
WHERE w.web_country = 'USA'
ORDER BY ss.total_quantity DESC NULLS LAST;
