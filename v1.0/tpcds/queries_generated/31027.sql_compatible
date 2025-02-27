
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, d_quarter_seq
    FROM date_dim
    WHERE d_year = 2023
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq, d.d_week_seq, d.d_quarter_seq
    FROM date_dim d
    INNER JOIN DateHierarchy dh ON d.d_date_sk > dh.d_date_sk 
    WHERE d.d_year = 2023
),
SalesSummary AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM DateHierarchy)
    GROUP BY s_store_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band_sk,
        cd.cd_dep_count,
        SUM(ws.ws_net_paid) AS total_web_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, hd.hd_income_band_sk, cd.cd_dep_count
)
SELECT 
    cd.income_band_sk,
    cd.cd_gender,
    SUM(ss.total_sales) AS total_store_sales,
    COUNT(cd.cd_demo_sk) AS customer_count,
    AVG(cd.total_web_sales) AS avg_web_sales_per_customer,
    MAX(ss.total_sales) AS max_store_sales,
    MIN(ss.total_sales) AS min_store_sales
FROM SalesSummary ss
JOIN CustomerDemographics cd ON ss.s_store_sk IN (
    SELECT s_store_sk 
    FROM store 
    WHERE s_division_id = cd.income_band_sk
)
GROUP BY cd.income_band_sk, cd.cd_gender
HAVING COUNT(cd.cd_demo_sk) > 10
ORDER BY total_store_sales DESC;
