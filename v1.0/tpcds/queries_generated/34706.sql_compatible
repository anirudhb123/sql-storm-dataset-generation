
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.ws_order_number
), SalesRanked AS (
    SELECT 
        sd.web_site_sk,
        sd.ws_order_number,
        sd.total_quantity,
        sd.total_sales,
        sd.rank,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS overall_rank
    FROM SalesData sd
    WHERE sd.total_sales IS NOT NULL
)
SELECT 
    s.web_site_sk,
    SUM(s.total_quantity) AS total_quantity,
    SUM(s.total_sales) AS total_sales,
    MAX(s.rank) AS highest_rank,
    MIN(s.overall_rank) AS lowest_overall_rank
FROM SalesRanked s
LEFT JOIN catalog_sales cs ON s.ws_order_number = cs.cs_order_number
JOIN (
    SELECT sm.sm_ship_mode_sk, sm.sm_type
    FROM ship_mode sm
    WHERE sm.sm_code IS NOT NULL
) sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY s.web_site_sk
HAVING COUNT(s.ws_order_number) > 5
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
