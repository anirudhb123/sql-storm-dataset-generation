
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_month_seq, d_year, 1 AS level
    FROM date_dim
    WHERE d_date = (SELECT MAX(d_date) FROM date_dim)

    UNION ALL

    SELECT d.d_date_sk, d.d_date, d.d_month_seq, d.d_year, level + 1
    FROM date_dim d
    INNER JOIN DateHierarchy dh ON d_month_seq = dh.d_month_seq - 1
    WHERE d_year = dh.d_year OR d_year = dh.d_year - 1
),

TotalSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM DateHierarchy)
    GROUP BY ws_bill_customer_sk
),

CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

SalesAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.customer_value,
        AVG(ts.total_sales) AS avg_sales,
        COUNT(DISTINCT ts.customer_sk) AS customer_count,
        COUNT(DISTINCT CASE WHEN cd.cd_marital_status = 'M' THEN ts.customer_sk END) AS married_customers
    FROM TotalSales ts
    JOIN CustomerDemographics cd ON ts.customer_sk = cd.c_customer_sk
    GROUP BY cd.cd_gender, cd.customer_value
)

SELECT 
    sa.cd_gender,
    sa.customer_value,
    sa.avg_sales,
    sa.customer_count,
    sa.married_customers,
    COALESCE((SELECT MAX(avg_sales) FROM SalesAnalysis), 0) AS max_avg_sales
FROM SalesAnalysis sa
WHERE sa.avg_sales > (SELECT COALESCE(AVG(avg_sales), 0) FROM SalesAnalysis)
ORDER BY sa.avg_sales DESC;

