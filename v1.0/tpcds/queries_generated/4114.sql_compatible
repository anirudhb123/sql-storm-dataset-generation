
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY
        ws.web_site_sk, ws.web_name
),
distinct_customers AS (
    SELECT
        ws.ws_web_site_sk,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM
        web_sales ws
    GROUP BY
        ws.ws_web_site_sk
)
SELECT
    r.web_name,
    r.total_sales,
    d.unique_customers,
    CASE 
        WHEN d.unique_customers > 0 THEN r.total_sales / d.unique_customers
        ELSE 0
    END AS average_sale_per_customer,
    COALESCE(r.sales_rank, 0) AS sales_rank
FROM
    ranked_sales r
FULL OUTER JOIN
    distinct_customers d ON r.web_site_sk = d.ws_web_site_sk
WHERE
    (r.total_sales > 10000 OR r.total_sales IS NULL)
ORDER BY
    COALESCE(r.total_sales, 0) DESC, average_sale_per_customer DESC;
