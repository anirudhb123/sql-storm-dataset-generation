
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_item_sk
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        COALESCE(i.i_item_desc, 'Unknown Item') AS item_description,
        COALESCE(sa.ca_city, 'Unknown City') AS city,
        d.d_year AS sales_year
    FROM sales_data sd
    LEFT JOIN item i ON sd.ws_item_sk = i.i_item_sk
    LEFT JOIN store s ON s.s_store_sk = (SELECT ss_store_sk FROM store_sales ss WHERE ss.ss_item_sk = sd.ws_item_sk LIMIT 1)
    LEFT JOIN customer_address sa ON sa.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = (SELECT MIN(ws_bill_customer_sk) FROM web_sales ws WHERE ws.ws_item_sk = sd.ws_item_sk LIMIT 1))
    CROSS JOIN date_dim d
    WHERE sd.rank <= 5
),
income_info AS (
    SELECT 
        cd.cd_gender,
        COUNT(cd.cd_demo_sk) AS demographic_count,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    ts.item_description,
    ts.city,
    ts.total_quantity,
    ts.total_net_profit,
    ii.cd_gender,
    ii.demographic_count,
    ii.avg_income_band
FROM top_sales ts
LEFT JOIN income_info ii ON ts.sales_year = (SELECT d_year FROM date_dim WHERE d_date_sk = (SELECT MIN(ws_sold_date_sk) FROM web_sales ws WHERE ws_item_sk = ts.ws_item_sk))
ORDER BY ts.total_net_profit DESC;
