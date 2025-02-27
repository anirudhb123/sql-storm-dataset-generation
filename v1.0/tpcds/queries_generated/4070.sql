
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 2) 
        AND 
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 3)
    GROUP BY ws.bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesWithDemographics AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        rs.total_sales,
        rs.order_count
    FROM CustomerInfo ci
    LEFT JOIN RankedSales rs ON ci.c_customer_sk = rs.bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        *,
        CASE 
            WHEN total_sales IS NULL THEN 'No Sales'
            WHEN total_sales > 10000 THEN 'Platinum'
            WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Gold'
            ELSE 'Silver' 
        END AS customer_value
    FROM SalesWithDemographics
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    COALESCE(hvc.total_sales, 0) AS total_sales,
    hvc.order_count,
    hvc.customer_value
FROM HighValueCustomers hvc
WHERE hvc.customer_value <> 'No Sales'
ORDER BY total_sales DESC, order_count DESC;
