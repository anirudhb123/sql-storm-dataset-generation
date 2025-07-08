WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_country = 'USA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, ah.level + 1
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_state = ah.ca_state AND a.ca_city <> ah.ca_city
    WHERE ah.level < 5
),
CustomerStats AS (
    SELECT 
        cd_gender, 
        COUNT(c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
ReturnData AS (
    SELECT 
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
)
SELECT
    ah.ca_city,
    ah.ca_state,
    cs.customer_count,
    cs.married_count,
    cs.single_count,
    cs.average_purchase_estimate,
    ss.total_sales,
    ss.total_orders,
    rd.total_returns,
    rd.total_return_value,
    COALESCE(NULLIF(cs.customer_count, 0), 1) AS safe_customer_count,
    CASE 
        WHEN ss.total_sales > 1000000 THEN 'High Volume'
        WHEN ss.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM AddressHierarchy ah
LEFT JOIN CustomerStats cs ON ah.ca_city = 'San Francisco'
JOIN SalesSummary ss ON ss.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
CROSS JOIN ReturnData rd
WHERE ah.level = 1
ORDER BY ah.ca_city, ah.ca_state;