
WITH RECURSIVE DateRange AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq
    FROM date_dim
    WHERE d_year BETWEEN 2018 AND 2023
    UNION ALL
    SELECT d_date_sk + 1, DATEADD(DAY, 1, d_date), d_year, d_month_seq, d_week_seq
    FROM DateRange
    WHERE d_date_sk < (SELECT MAX(d_date_sk) FROM date_dim)
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        sd.total_sales,
        sd.order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F'
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.order_count, 0) AS order_count,
    DENSE_RANK() OVER (ORDER BY COALESCE(cs.total_sales, 0) DESC) AS sales_rank,
    CASE 
        WHEN cs.order_count > 0 THEN cs.total_sales / cs.order_count 
        ELSE NULL 
    END AS avg_sales_per_order,
    (SELECT COUNT(*)
     FROM customer_address ca 
     WHERE ca.ca_state = 'CA') AS total_addresses_in_california
FROM CustomerSales cs
WHERE cs.total_sales > (SELECT AVG(total_sales) FROM SalesData);
