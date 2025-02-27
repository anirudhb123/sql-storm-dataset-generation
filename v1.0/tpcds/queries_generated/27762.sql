
WITH AddressSummary AS (
    SELECT
        ca.city AS city,
        ca.state AS state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS unique_education_levels
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        ca.city,
        ca.state
),
DateSummary AS (
    SELECT
        d.d_year AS year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
)
SELECT
    a.city,
    a.state,
    a.customer_count,
    a.male_count,
    a.female_count,
    a.single_count,
    a.married_count,
    a.unique_education_levels,
    d.year,
    d.total_sales,
    d.total_orders
FROM
    AddressSummary a
JOIN
    DateSummary d ON a.customer_count > 0 
ORDER BY
    a.city, 
    a.state, 
    d.year;
