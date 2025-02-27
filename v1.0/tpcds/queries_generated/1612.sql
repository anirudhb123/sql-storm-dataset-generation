
WITH Sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
),
Top_customers AS (
    SELECT
        s.ws_bill_customer_sk,
        s.total_sales,
        s.total_orders,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM
        Sales_summary s
    JOIN
        customer c ON s.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        s.sales_rank = 1
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.c_email_address,
    tc.total_sales,
    tc.total_orders,
    CASE 
        WHEN tc.income_band IS NULL THEN 'Not Specified'
        ELSE (SELECT CONCAT(ib.ib_lower_bound, ' - ', ib.ib_upper_bound) FROM income_band ib WHERE ib.ib_income_band_sk = tc.income_band)
    END AS income_range,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = tc.ws_bill_customer_sk AND ss.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)) AS store_purchases
FROM
    Top_customers tc
WHERE
    tc.total_sales > 1000
ORDER BY 
    tc.total_sales DESC
LIMIT 10;
