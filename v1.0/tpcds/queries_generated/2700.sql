
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
IncomeBands AS (
    SELECT 
        h.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS customer_count
    FROM household_demographics h
    JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY h.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
    ORDER BY total_net_profit DESC
    LIMIT 10
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_net_profit,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(ibs.customer_count, 0) AS income_band_count,
    ts.s_store_name,
    ts.total_net_profit AS store_profit
FROM CustomerStats cs
LEFT JOIN IncomeBands ibs ON cs.c_customer_sk = ibs.hd_demo_sk
JOIN TopStores ts ON ts.total_net_profit > cs.total_net_profit
WHERE cs.total_net_profit > 1000 
  AND (cs.cd_marital_status = 'M' OR cs.cd_gender = 'F')
ORDER BY cs.total_net_profit DESC, ts.s_store_name;
