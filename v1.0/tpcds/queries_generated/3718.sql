
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_sales
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        cd.c_customer_id,
        SUM(sd.total_sales) AS total_spent
    FROM CustomerData cd
    JOIN SalesData sd ON cd.c_customer_id = sd.web_site_id
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY cd.c_customer_id
    HAVING SUM(sd.total_sales) > 1000
),
TopStores AS (
    SELECT 
        s.s_store_id,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS store_rank
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_id
    HAVING COUNT(ss.ss_ticket_number) > 50
)
SELECT 
    j.web_site_id,
    j.total_sales,
    j.order_count,
    cc.c_customer_id,
    cc.total_spent AS high_value_spent,
    ts.s_store_id,
    ts.total_transactions,
    ts.total_profit
FROM SalesData j
FULL OUTER JOIN HighValueCustomers cc ON j.web_site_id = cc.c_customer_id
FULL OUTER JOIN TopStores ts ON ts.total_transactions > 100
WHERE j.total_sales IS NOT NULL OR cc.total_spent IS NOT NULL OR ts.total_profit IS NOT NULL
ORDER BY j.total_sales DESC, cc.total_spent DESC, ts.total_profit DESC;
