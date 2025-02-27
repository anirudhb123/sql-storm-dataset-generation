
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_spending
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressAnalysis AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
),
PivottedSales AS (
    SELECT 
        ca.ca_city,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count,
        CASE 
            WHEN SUM(ss.ss_sales_price) > 10000 THEN 'High'
            WHEN SUM(ss.ss_sales_price) BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON s.s_street_name = ca.ca_street_name
    GROUP BY ca.ca_city
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    aa.ca_city,
    pp.total_sales,
    pp.sales_category
FROM RankedCustomers rc
JOIN AddressAnalysis aa ON rc.c_customer_sk = aa.customer_count
JOIN PivottedSales pp ON aa.ca_city = pp.ca_city
WHERE rc.rank_by_spending <= 5
ORDER BY pp.total_sales DESC, rc.full_name;
