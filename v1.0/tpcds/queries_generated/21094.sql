
WITH customer_stats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount,
        AVG(COALESCE(sr.return_quantity, 0)) AS avg_return_quantity,
        (SELECT COUNT(*) 
         FROM web_sales ws 
         WHERE ws.bill_customer_sk = c.c_customer_sk) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_name,
        w.w_city,
        COUNT(DISTINCT ss.ticket_number) AS total_sales,
        SUM(ss.net_profit) AS total_net_profit
    FROM 
        warehouse w
    LEFT JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_name, w.w_city
),
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT hd.hd_demo_sk) AS household_count,
        CASE 
            WHEN COUNT(DISTINCT hd.hd_demo_sk) = 0 THEN 0
            ELSE SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) * 1.0 / COUNT(DISTINCT hd.hd_demo_sk)
        END AS marital_ratio
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_returns,
    cs.total_return_amount,
    cs.avg_return_quantity,
    wi.w_warehouse_name,
    wi.w_city,
    wi.total_sales,
    wi.total_net_profit,
    id.household_count,
    id.marital_ratio
FROM 
    customer_stats cs
LEFT JOIN 
    warehouse_info wi ON cs.total_web_sales > 0
LEFT JOIN 
    income_distribution id ON cs.total_returns > 10
WHERE 
    (cs.cd_gender = 'M' OR cs.cd_gender IS NULL)
    AND cs.total_return_amount >= (
        SELECT AVG(total_return_amount) FROM customer_stats
    )
ORDER BY 
    cs.total_returns DESC, wi.total_net_profit DESC
LIMIT 100;
