
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_address_count,
        COUNT(ca_address_id) AS total_address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
SalesByMonth AS (
    SELECT 
        DATE_TRUNC('month', d.d_date) AS sales_month,
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY sales_month
)
SELECT 
    a.ca_state,
    a.unique_address_count,
    a.total_address_count,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    d.cd_gender,
    d.demographic_count,
    d.avg_dependents,
    d.total_purchase_estimate,
    c.total_orders,
    c.total_spent,
    s.sales_month,
    s.total_sales
FROM AddressStats a
JOIN DemographicStats d ON TRUE
JOIN CustomerSales c ON TRUE
JOIN SalesByMonth s ON TRUE
ORDER BY a.ca_state, d.cd_gender, c.total_spent DESC, s.sales_month;
