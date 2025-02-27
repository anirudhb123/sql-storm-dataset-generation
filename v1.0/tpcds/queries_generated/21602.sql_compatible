
WITH RECURSIVE Address_CTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country
    FROM customer_address a
    JOIN Address_CTE c ON a.ca_address_sk = c.ca_address_sk
    WHERE a.ca_country = c.ca_country AND a.ca_city <> c.ca_city
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_quantity) AS avg_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
Filtered_Customer AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        (SELECT COUNT(*) 
         FROM ship_mode 
         WHERE sm_ship_mode_sk = ANY (
             SELECT DISTINCT ws_ship_mode_sk 
             FROM web_sales 
             WHERE ws_bill_customer_sk = c.c_customer_sk AND ws_net_paid > 100
         )) AS high_value_ship_count,
        (CASE 
            WHEN d.cd_gender = 'M' THEN 'Mr. ' || c.c_first_name 
            ELSE 'Ms. ' || c.c_first_name 
        END) AS full_name
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_month IS NOT NULL 
      AND EXISTS (SELECT 1 FROM Address_CTE a WHERE a.ca_city = c.c_first_name)
),
Final_Report AS (
    SELECT
        fc.c_customer_sk,
        fc.full_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        fc.high_value_ship_count,
        (SELECT MIN(cell) 
         FROM (VALUES (fc.cd_purchase_estimate), (ss.order_count), (fc.high_value_ship_count)) AS Orders(cell)
         WHERE cell IS NOT NULL) AS min_non_null_value
    FROM Filtered_Customer fc
    LEFT JOIN SalesSummary ss ON fc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    f.full_name,
    f.total_sales,
    f.order_count,
    f.high_value_ship_count,
    CASE 
        WHEN f.min_non_null_value IS NULL THEN 'No Sales' 
        ELSE CAST(f.min_non_null_value AS VARCHAR)
    END AS min_orders_or_high_ships
FROM Final_Report f
WHERE f.total_sales > (SELECT AVG(total_sales) FROM Final_Report)
ORDER BY f.total_sales DESC NULLS LAST;
