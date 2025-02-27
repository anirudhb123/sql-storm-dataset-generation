
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), gender_income AS (
    SELECT 
        ci.cd_gender,
        ib.ib_income_band_sk,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count
    FROM customer_info ci
    LEFT JOIN household_demographics hd ON ci.c_current_cdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ci.cd_gender, ib.ib_income_band_sk
), top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS item_rank
    FROM sales_summary ss
    WHERE ss.rank = 1
)
SELECT 
    gi.cd_gender,
    ib.ib_income_band_sk,
    COUNT(DISTINCT ti.ws_item_sk) AS top_item_count,
    AVG(ti.total_sales) AS average_sales,
    SUM(ti.total_quantity) AS total_quantity_sold
FROM gender_income gi
JOIN top_items ti ON gi.ib_income_band_sk = ti.ws_item_sk
LEFT JOIN income_band ib ON gi.ib_income_band_sk = ib.ib_income_band_sk
GROUP BY gi.cd_gender, ib.ib_income_band_sk
ORDER BY gi.cd_gender, ib.ib_income_band_sk;
