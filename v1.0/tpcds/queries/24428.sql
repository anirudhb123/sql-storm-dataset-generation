
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_zip, ca_city, ca_state, ca_country 
    FROM customer_address 
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT c.ca_address_sk, c.ca_zip, c.ca_city, c.ca_state, c.ca_country 
    FROM customer_address c
    INNER JOIN AddressCTE a ON c.ca_city = a.ca_city AND c.ca_state = a.ca_state
    WHERE a.ca_country IS NULL
), CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        d.d_year,
        cd.cd_gender,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_sales_price) AS total_spent,
        AVG(s.ss_sales_price) AS average_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN AddressCTE a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE cd.cd_gender IS NOT NULL AND (cd.cd_marital_status = 'M' OR cd.cd_dep_count > 2)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, d.d_year, cd.cd_gender
), GenderIncomeBand AS (
    SELECT 
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT cs.cs_order_number) AS number_of_orders
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.c_birth_year,
    cs.total_sales,
    cs.total_spent,
    cs.average_spent,
    COALESCE(gib.number_of_orders, 0) AS orders_in_income_band,
    CASE 
        WHEN cs.c_birth_year IS NULL THEN 'Year Unknown'
        WHEN cs.c_birth_year < 1960 THEN 'Baby Boomer'
        WHEN cs.c_birth_year BETWEEN 1960 AND 1980 THEN 'Generation X'
        ELSE 'Millennial or Younger'
    END AS generation_category
FROM CustomerSummary cs
LEFT JOIN GenderIncomeBand gib ON cs.cd_gender = gib.cd_gender
WHERE cs.total_spent > 1000 
  AND (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = cs.c_customer_sk) > 5
ORDER BY cs.total_spent DESC, cs.c_last_name ASC
LIMIT 10 OFFSET 5;
