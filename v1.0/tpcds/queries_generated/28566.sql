
WITH address_stats AS (
    SELECT
        ca.city AS address_city,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd.gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        ca.city
),
sales_summary AS (
    SELECT
        d.year AS sales_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.year
)
SELECT
    a.address_city,
    a.customer_count,
    a.male_count,
    a.female_count,
    a.avg_purchase_estimate,
    s.sales_year,
    s.total_sales,
    s.total_orders,
    s.avg_sales_price
FROM
    address_stats a
JOIN
    sales_summary s ON a.customer_count > 100 AND s.total_sales > 10000
ORDER BY
    a.customer_count DESC, s.total_sales DESC;
