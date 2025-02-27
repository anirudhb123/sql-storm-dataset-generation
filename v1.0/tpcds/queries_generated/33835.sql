
WITH RECURSIVE IncomeBandCTE AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN IncomeBandCTE cte ON ib.ib_lower_bound >= cte.ib_upper_bound
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM customer_address ca
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cs.total_sales) AS total_sales,
    COUNT(DISTINCT cs.order_count) AS total_orders,
    CONCAT(adr.full_address, ' (Last Purchase: ', DATE_FORMAT(FROM_UNIXTIME(cs.last_purchase_date), '%Y-%m-%d'), ')') AS customer_info,
    (CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END) AS marital_status_desc,
    ib.ib_income_band_sk,
    (SELECT COUNT(*) FROM CustomerSales cs_inner WHERE cs_inner.total_sales > 1000) AS high_value_customers
FROM customer_demographics cd
LEFT JOIN CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
LEFT JOIN AddressDetails adr ON cd.cd_demo_sk = adr.ca_address_sk
LEFT JOIN IncomeBandCTE ib ON cd.cd_credit_rating IS NOT NULL
GROUP BY cd.cd_gender, cd.cd_marital_status, adr.full_address, ib.ib_income_band_sk
HAVING COUNT(cs.order_count) > 5
ORDER BY total_sales DESC, cd.cd_gender;
