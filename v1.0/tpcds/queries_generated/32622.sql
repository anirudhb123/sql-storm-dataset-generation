
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS generation
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.generation + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)
, latest_sales AS (
    SELECT 
        ws.ws_customer_sk,
        MAX(ws.ws_sold_date_sk) AS last_order_date,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM web_sales ws
    GROUP BY ws.ws_customer_sk
)
, customer_info AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        r.r_reason_desc,
        CASE 
            WHEN r.r_reason_desc IS NOT NULL THEN 1 
            ELSE 0 
        END AS return_flag,
        ls.last_order_date,
        ls.total_spent
    FROM customer_hierarchy ch
    LEFT JOIN customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT cr.refunded_customer_sk, r.r_reason_desc
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        GROUP BY cr.refunded_customer_sk, r.r_reason_desc
    ) r ON ch.c_customer_sk = r.refunded_customer_sk
    LEFT JOIN latest_sales ls ON ch.c_customer_sk = ls.ws_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ib.ib_income_band_sk, -1) AS income_band,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_total_sales,
    SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS catalog_total_sales,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_count,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_returns_count,
    COUNT(DISTINCT wr.wr_order_number) AS web_returns_count,
    ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
FROM customer_info ci
LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_sales cs ON ci.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN store_returns sr ON ci.c_customer_sk = sr.sr_customer_sk
LEFT JOIN catalog_returns cr ON ci.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN web_returns wr ON ci.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN income_band ib ON ci.cd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ib.ib_income_band_sk
HAVING SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) > 1000
ORDER BY sales_rank;
