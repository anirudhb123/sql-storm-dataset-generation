
WITH RECURSIVE sales_summary AS (
    SELECT
        ws.sold_date_sk,
        ws.item_sk,
        sum(ws.ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY ws.sold_date_sk) AS sale_rank
    FROM
        web_sales ws
    GROUP BY
        ws.sold_date_sk, ws.item_sk
),
address_summary AS (
    SELECT
        ca.city,
        ca.state,
        COUNT(DISTINCT c.customer_sk) AS customer_count,
        SUM(d.cd_purchase_estimate) AS total_purchase_estimate
    FROM
        customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    GROUP BY
        ca.city, ca.state
),
complex_analysis AS (
    SELECT
        ss.sold_date_sk,
        ss.item_sk,
        ss.total_sales,
        asum.customer_count,
        asum.total_purchase_estimate,
        (CASE 
            WHEN asum.customer_count IS NULL THEN 0
            ELSE ss.total_sales / asum.customer_count 
        END) AS avg_sale_per_customer
    FROM
        sales_summary ss
    JOIN address_summary asum ON ss.sold_date_sk = asum.city
    WHERE
        ss.sale_rank = 1
)
SELECT
    da.d_date,
    ca.ca_city,
    SUM(ca.total_sales) AS total_sales_by_city,
    AVG(ca.avg_sale_per_customer) AS avg_sale_per_customer
FROM
    complex_analysis ca
JOIN date_dim da ON ca.sold_date_sk = da.d_date_sk
WHERE
    da.d_year = 2023
GROUP BY
    da.d_date, ca.ca_city
ORDER BY
    total_sales_by_city DESC, avg_sale_per_customer DESC
LIMIT 10;
