
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
    UNION ALL
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IS NOT NULL
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS total_return_amt,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
        COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_web_return_amt
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
date_analysis AS (
    SELECT 
        d.d_date_sk,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date_sk, d.d_year
)
SELECT 
    d.c_first_name,
    d.c_last_name,
    d.cd_gender,
    ia.total_quantity,
    ia.total_sales,
    da.web_order_count,
    da.total_web_sales,
    ca.return_count,
    ca.total_return_amt,
    da.total_web_return_amt
FROM customer_analysis ca
JOIN sales_summary ia ON ca.c_customer_sk = ia.ws_item_sk
JOIN date_analysis da ON ia.ws_sold_date_sk = da.d_date_sk
WHERE (ca.hd_income_band_sk IS NULL OR ca.hd_income_band_sk = 1)
AND da.d_year >= 2022
ORDER BY ca.total_return_amt DESC, da.total_web_sales DESC
LIMIT 100;
