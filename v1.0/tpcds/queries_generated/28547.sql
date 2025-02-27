
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(ca_city) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM customer_address
    GROUP BY ca_state
),
gender_distribution AS (
    SELECT 
        cd_gender,
        COUNT(c.customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
),
monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', d_date) AS sale_month,
        SUM(ws_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY sale_month
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.address_count,
    a.cities,
    a.avg_gmt_offset,
    g.cd_gender,
    g.customer_count,
    g.avg_purchase_estimate,
    m.sale_month,
    m.total_sales
FROM address_summary a
JOIN gender_distribution g ON g.customer_count > 100
JOIN monthly_sales m ON m.total_sales > 10000
ORDER BY a.ca_state, g.cd_gender, m.sale_month DESC;
