
WITH RECURSIVE SalesData AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count,
        MAX(cs_sold_date_sk) AS last_purchase_date
    FROM
        catalog_sales
    GROUP BY
        cs_bill_customer_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_first_name) AS rn
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT
        cust.c_customer_sk,
        cust.c_first_name || ' ' || cust.c_last_name AS full_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        CASE
            WHEN COALESCE(sd.total_sales, 0) > 1000 THEN 'High Value'
            WHEN COALESCE(sd.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        CASE
            WHEN COALESCE(hd.income_band, -1) = -1 THEN 'Unknown Income'
            ELSE CAST(hd.income_band AS VARCHAR)
        END AS income_band
    FROM
        CustomerDetails cust
    LEFT JOIN SalesData sd ON cust.c_customer_sk = sd.cs_bill_customer_sk
    JOIN household_demographics hd ON cust.c_customer_sk = hd.hd_demo_sk
)
SELECT
    s.full_name,
    s.total_sales,
    s.order_count,
    s.customer_value,
    s.income_band,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No Sales'
        WHEN NOT (s.total_sales > 1000 OR s.total_sales < 0) THEN 'Suspicious Sales Value'
        ELSE 'Valid Sales'
    END AS sales_status
FROM
    SalesSummary s
WHERE
    s.customer_value != 'Low Value'
    AND (s.income_band IS NOT NULL OR s.income_band <> 'Unknown Income')
ORDER BY
    s.total_sales DESC
OFFSET 10 ROWS
FETCH NEXT 5 ROWS ONLY;
