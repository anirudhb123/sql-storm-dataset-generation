
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_moy = 1)
    GROUP BY ws_item_sk
),
TopSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerIncome AS (
    SELECT 
        cd.cd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
FinalReport AS (
    SELECT 
        ts.c_customer_sk,
        ts.c_first_name,
        ts.c_last_name,
        ci.ib_lower_bound,
        ci.ib_upper_bound,
        ts.total_spent,
        ts.order_count,
        COALESCE((SELECT total_net_profit FROM SalesCTE WHERE ws_item_sk = (SELECT MIN(ws_item_sk) FROM web_sales)), 0) AS lowest_net_profit_item
    FROM TopSales ts
    LEFT JOIN CustomerIncome ci ON ts.c_customer_sk = ci.cd_demo_sk
    WHERE ts.total_spent > 1000
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.ib_lower_bound,
    f.ib_upper_bound,
    f.total_spent,
    f.order_count,
    CASE 
        WHEN f.lowest_net_profit_item IS NOT NULL THEN 'Has lowest profit item'
        ELSE 'No minimum profit found'
    END AS profit_item_status
FROM FinalReport f
ORDER BY f.total_spent DESC, f.order_count DESC
LIMIT 50;
