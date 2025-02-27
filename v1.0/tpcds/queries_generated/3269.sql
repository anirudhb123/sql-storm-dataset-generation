
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_online_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS online_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        (ib.ib_lower_bound + ib.ib_upper_bound) / 2 AS average_income,
        COUNT(hd.hd_demo_sk) AS household_count
    FROM household_demographics AS hd
    JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    cs.c_customer_id,
    cs.total_online_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    cd.customer_count,
    cd.cd_gender,
    cd.cd_marital_status,
    id.average_income,
    id.household_count
FROM customer_sales AS cs
JOIN customer_demographics AS cd ON cs.c_customer_id IN (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL)
LEFT JOIN income_distribution AS id ON cd.customer_count > 0
WHERE (cs.total_online_sales + cs.total_catalog_sales + cs.total_store_sales) > 1000
ORDER BY cs.total_online_sales DESC, cs.total_catalog_sales DESC
LIMIT 100;
