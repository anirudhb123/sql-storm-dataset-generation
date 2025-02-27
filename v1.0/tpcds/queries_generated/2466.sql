
WITH sales_data AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                   AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws.web_site_sk, ws.ws_sold_date_sk
),
return_data AS (
    SELECT 
        wr.wr_web_page_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_web_page_sk
),
combined_data AS (
    SELECT 
        sd.web_site_sk,
        sd.ws_sold_date_sk,
        sd.total_quantity,
        sd.total_sales,
        rd.total_returns,
        rd.total_return_amt,
        (sd.total_sales - COALESCE(rd.total_return_amt, 0)) AS net_sales
    FROM sales_data sd
    LEFT JOIN return_data rd ON sd.web_site_sk = rd.wr_web_page_sk
),
income_band_summary AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN household_demographics hd ON c.c_current_cdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    cd.web_site_sk,
    cd.ws_sold_date_sk,
    cd.total_quantity,
    cd.total_sales,
    cd.total_returns,
    cd.net_sales,
    ibs.income_band_sk,
    ibs.customer_count,
    ibs.total_profit
FROM combined_data cd
JOIN income_band_summary ibs ON cd.web_site_sk = ibs.ib_income_band_sk
ORDER BY cd.net_sales DESC, ibs.total_profit DESC
LIMIT 100;
