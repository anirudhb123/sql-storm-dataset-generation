
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_hdemo_sk IS NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_hdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (
        SELECT MIN(d_date_sk)
        FROM date_dim dd
        WHERE dd.d_year = 2023
    )
    GROUP BY ws.ws_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
RankedSales AS (
    SELECT 
        sd.ws_customer_sk,
        sd.total_sales,
        sd.order_count,
        RANK() OVER (PARTITION BY d.cd_gender ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
    JOIN demographics d ON sd.ws_customer_sk = d.cd_demo_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ds.total_sales,
    ds.order_count,
    ds.sales_rank,
    CASE 
        WHEN ds.sales_rank <= 10 THEN 'Top Customer'
        WHEN ds.total_sales IS NULL THEN 'No Sales'
        ELSE 'Regular Customer'
    END AS customer_status
FROM CustomerHierarchy ch
LEFT JOIN RankedSales ds ON ch.c_customer_sk = ds.ws_customer_sk
WHERE ch.level <= 3
ORDER BY ch.c_last_name, ch.c_first_name;
