
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-31')
    GROUP BY ss_store_sk
),
TopStores AS (
    SELECT 
        rs.ss_store_sk,
        rs.total_sales,
        COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown') AS best_selling_customer,
        SUM(ws_quantity) AS total_web_sales
    FROM RankedSales rs
    LEFT JOIN store s ON rs.ss_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws ON ws.ws_ship_customer_sk = s.s_store_sk
    LEFT JOIN customer c ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE rs.sales_rank = 1
    GROUP BY rs.ss_store_sk, rs.total_sales, c.c_first_name, c.c_last_name
),
IncomeDistribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(*) AS demo_count,
        MAX(h.hd_buy_potential) AS highest_potential
    FROM household_demographics h
    GROUP BY h.hd_income_band_sk
)
SELECT 
    ts.ss_store_sk,
    ts.total_sales,
    ts.best_selling_customer,
    id.demo_count,
    id.highest_potential
FROM TopStores ts
JOIN IncomeDistribution id ON id.hd_income_band_sk = (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound <= ts.total_sales/100 AND ib_upper_bound >= ts.total_sales/100)
WHERE 
    ts.total_sales IS NOT NULL
ORDER BY ts.total_sales DESC NULLS LAST
LIMIT 10
UNION ALL
SELECT 
    NULL AS ss_store_sk,
    SUM(ws_net_paid_inc_tax) AS total_sales,
    'Online Total' AS best_selling_customer,
    COUNT(DISTINCT ws_bill_customer_sk) AS demo_count,
    MAX(hd_buy_potential) AS highest_potential
FROM web_sales ws
LEFT JOIN household_demographics h ON h.hd_demo_sk = ws.ws_bill_cdemo_sk
WHERE ws_sold_date_sk BETWEEN 
    (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
    (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-31')
HAVING 
    SUM(ws_net_paid_inc_tax) IS NOT NULL
ORDER BY 2 DESC;
