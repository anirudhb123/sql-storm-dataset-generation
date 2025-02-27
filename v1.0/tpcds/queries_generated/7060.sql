
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    WHERE cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
AddressDetails AS (
    SELECT 
        h.hd_demo_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM household_demographics h
    JOIN customer_address ca ON h.hd_demo_sk = ca.ca_address_sk
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country
FROM HighValueCustomers hvc
JOIN AddressDetails ad ON hvc.c_customer_id = ad.hd_demo_sk
ORDER BY hvc.total_sales DESC
LIMIT 10;
