
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2458000 AND 2458006
    GROUP BY ws.web_site_sk, ws.ws_order_number, ws.ws_item_sk
),
Filtered_CTE AS (
    SELECT 
        ff.web_site_sk,
        ff.ws_order_number,
        ff.total_quantity,
        ff.total_net_paid,
        fd.d_year,
        cd.cd_gender,
        (CASE 
             WHEN fd.d_year < 2022 THEN 'Pre-2022'
             WHEN fd.d_year = 2022 THEN 'Year 2022'
             ELSE 'Post-2022' END) AS year_band
    FROM Sales_CTE ff
    JOIN date_dim fd ON fd.d_date_sk = ff.ws_order_number
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = ff.ws_item_sk
    WHERE ff.total_net_paid > 100
),
Final_Result AS (
    SELECT 
        fc.web_site_sk,
        fc.total_quantity,
        fc.total_net_paid,
        fc.d_year,
        fc.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY fc.year_band ORDER BY fc.total_net_paid DESC) AS yearly_rank
    FROM Filtered_CTE fc
    WHERE fc.total_quantity IS NOT NULL AND fc.total_quantity <> 0
)
SELECT 
    fr.web_site_sk,
    fr.total_quantity,
    fr.total_net_paid,
    fr.d_year,
    fr.cd_gender,
    fr.yearly_rank
FROM Final_Result fr
WHERE fr.yearly_rank < 10
ORDER BY fr.d_year, fr.total_net_paid DESC
UNION ALL
SELECT 
    NULL AS web_site_sk,
    SUM(NULLIF(fr.total_quantity, 0)) AS total_quantity,
    SUM(fr.total_net_paid) AS total_net_paid,
    NULL AS d_year,
    'UNKNOWN' AS cd_gender,
    NULL AS yearly_rank
FROM Final_Result fr
WHERE fr.cd_gender IS NULL;
