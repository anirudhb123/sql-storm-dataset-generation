
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn,
        SUM(ws_net_paid) OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
item_sales_summary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(MAX(rs.ws_sales_price), 0) AS max_sales_price,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COALESCE(cond_high.income_band, 'Not Specified') AS income_band
    FROM item i
    LEFT JOIN ranked_sales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rn = 1
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = (SELECT MIN(hd_demo_sk) FROM household_demographics)
    LEFT JOIN income_band cond_high ON hd.hd_income_band_sk = cond_high.ib_income_band_sk
    GROUP BY i.i_item_id, i.i_item_desc, cond_high.income_band
),
sales_analysis AS (
    SELECT 
        iss.i_item_id,
        iss.i_item_desc,
        iss.max_sales_price,
        iss.total_web_sales,
        iss.total_store_sales,
        (iss.total_web_sales + iss.total_store_sales) AS total_sales,
        CASE 
            WHEN iss.total_web_sales > 0 AND iss.total_store_sales > 0 THEN 'Both Channels'
            WHEN iss.total_web_sales > 0 THEN 'Web Only'
            WHEN iss.total_store_sales > 0 THEN 'Store Only'
            ELSE 'No Sales'
        END AS sales_channel
    FROM item_sales_summary iss
)
SELECT 
    sa.*,
    COALESCE(d.d_day_name, 'Unknown') AS sales_day
FROM sales_analysis sa
LEFT JOIN date_dim d ON d.d_date_sk = (
    SELECT MAX(ws_sold_date_sk)
    FROM web_sales ws
    WHERE ws.ws_item_sk = sa.i_item_id
)
ORDER BY total_sales DESC
LIMIT 50;
