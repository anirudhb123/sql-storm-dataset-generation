
WITH RECURSIVE income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk = 1
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_ranges ir ON ir.ib_income_band_sk + 1 = ib.ib_income_band_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(ROUND(SUM(ws.ws_net_profit), 2), 0) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(ROUND(SUM(ws.ws_net_profit), 2), 0) DESC) AS profit_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_credit_rating IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM household_demographics hd
            WHERE hd.hd_demo_sk = cd.cd_demo_sk
                AND hd.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_ranges)
        )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
sales_summary AS (
    SELECT
        cs.cs_item_sk,
        COUNT(cs.cs_order_number) AS order_count,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
                                 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY cs.cs_item_sk
)
SELECT ci.c_first_name,
       ci.c_last_name,
       ci.cd_gender,
       ci.total_net_profit,
       ci.total_orders,
       ss.order_count AS item_order_count,
       ss.total_net_profit AS item_net_profit
FROM customer_info ci
JOIN sales_summary ss ON ci.c_customer_sk = ss.cs_item_sk
WHERE ci.total_net_profit > 100.00
  AND (ci.cd_marital_status IN ('M', 'S') OR ci.total_orders > 5)
ORDER BY ci.total_net_profit DESC, ci.c_last_name ASC
LIMIT 100;
