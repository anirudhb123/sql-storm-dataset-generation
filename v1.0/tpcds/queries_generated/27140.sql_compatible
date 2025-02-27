
WITH StringAggregation AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        STRING_AGG(DISTINCT CONCAT(a.ca_street_number, ' ', a.ca_street_name, ' ', a.ca_city, ', ', a.ca_state, ' ', a.ca_zip), '; ') AS addresses,
        COUNT(DISTINCT d.d_date) AS purchase_dates,
        SUM(CASE WHEN d.d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_purchases,
        SUM(CASE WHEN dc.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
        SUM(CASE WHEN dc.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers
    FROM customer c
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics dc ON c.c_current_cdemo_sk = dc.cd_demo_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT 
    full_name,
    addresses,
    purchase_dates,
    holiday_purchases,
    CONCAT('Male: ', male_customers, ', Female: ', female_customers) AS gender_distribution
FROM StringAggregation
ORDER BY purchase_dates DESC, full_name;
