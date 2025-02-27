
WITH RECURSIVE IncomeBands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk = 1

    UNION ALL

    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN IncomeBands ib_recursive ON ib.ib_income_band_sk = ib_recursive.ib_income_band_sk + 1
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS item_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        cd.cd_demo_sk,
        CD.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        MAX(cs.cs_net_profit) AS max_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_demo_sk, cd.cd_gender, hd.hd_income_band_sk
)
SELECT
    cs.c_customer_sk,
    cs.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cs.order_count,
    cs.max_profit,
    sd.total_quantity,
    sd.total_net_paid,
    sd.avg_net_profit
FROM CustomerStats cs
JOIN IncomeBands ib ON cs.hd_income_band_sk = ib.ib_income_band_sk
JOIN SalesData sd ON sd.ws_item_sk IN (SELECT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = cs.c_customer_sk)
WHERE cs.order_count > 5
ORDER BY cs.max_profit DESC, cs.order_count DESC;
