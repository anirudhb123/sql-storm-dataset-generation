
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
ProductStats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_price,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price
    FROM item AS i
    LEFT JOIN web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
), 
IncomeDistribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(hd.hd_demo_sk) AS household_count,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM household_demographics AS hd
    LEFT JOIN customer AS c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)

SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_profit,
    cs.purchase_count,
    ps.total_sold,
    ps.avg_price,
    ps.max_price,
    ps.min_price,
    id.household_count,
    id.customer_count
FROM CustomerStats AS cs
JOIN ProductStats AS ps ON cs.purchase_count > 0
LEFT JOIN IncomeDistribution AS id ON id.customer_count > 0
WHERE cs.total_profit > (SELECT AVG(total_profit) FROM CustomerStats)
ORDER BY cs.total_profit DESC, ps.total_sold DESC
LIMIT 100;
