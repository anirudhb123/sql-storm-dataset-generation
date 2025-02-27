
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        a.ca_city,
        a.ca_state,
        a.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
    GROUP BY ws.ws_bill_customer_sk
),
CustomerSalesInfo AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        cs.total_sales,
        cs.total_discount,
        cs.order_count
    FROM CustomerInfo ci
    LEFT JOIN SalesData cs ON ci.c_customer_id = cs.ws_bill_customer_sk
)
SELECT 
    csi.c_customer_id,
    csi.c_first_name,
    csi.c_last_name,
    csi.cd_gender,
    csi.cd_marital_status,
    csi.cd_education_status,
    csi.cd_purchase_estimate,
    COALESCE(csi.total_sales, 0) AS total_sales,
    COALESCE(csi.total_discount, 0) AS total_discount,
    COALESCE(csi.order_count, 0) AS order_count,
    DENSE_RANK() OVER (ORDER BY COALESCE(csi.total_sales, 0) DESC) AS sales_rank
FROM CustomerSalesInfo csi
WHERE csi.cd_purchase_estimate > 10000
ORDER BY total_sales DESC
LIMIT 100;
