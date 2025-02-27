
WITH RECURSIVE IncomeCTE AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL 
    UNION ALL
    SELECT i.ib_income_band_sk, i.ib_lower_bound, i.ib_upper_bound
    FROM income_band i
    JOIN IncomeCTE cte ON i.ib_lower_bound > cte.ib_upper_bound
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales_price
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY ws.ws_sold_date_sk
),
CustomerAge AS (
    SELECT 
        c.c_customer_sk,
        YEAR(CURRENT_DATE) - c.c_birth_year AS customer_age,
        RANK() OVER (PARTITION BY c.c_preferred_cust_flag ORDER BY YEAR(CURRENT_DATE) - c.c_birth_year DESC) AS age_rank
    FROM customer c
)
SELECT 
    ca.ca_city,
    da.total_quantity,
    da.total_net_paid,
    da.total_ext_sales_price,
    ib.ib_income_band_sk,
    CASE 
        WHEN da.total_net_paid IS NULL THEN 'No Sales'
        ELSE 
            CASE 
                WHEN da.total_net_paid BETWEEN 0 AND 100 THEN 'Low Revenue'
                WHEN da.total_net_paid BETWEEN 101 AND 500 THEN 'Medium Revenue'
                ELSE 'High Revenue'
            END
    END AS revenue_category,
    COALESCE(ca.c_birth_country, 'Unknown') AS birth_country
FROM SalesData da
LEFT JOIN customer_address ca ON da.ws_sold_date_sk = ca.ca_address_sk
LEFT JOIN IncomeCTE ib ON da.total_quantity BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
JOIN CustomerAge ca ON ca.c_customer_sk = da.ws_bill_customer_sk
WHERE 
    (ca.c_birth_month IS NULL OR ca.c_birth_month = 12)
    AND da.total_quantity > 10
ORDER BY da.total_net_paid DESC, ca.ca_city ASC
LIMIT 50 OFFSET 10;
