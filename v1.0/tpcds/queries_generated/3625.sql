
WITH sales_summary AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year >= 1980
    GROUP BY
        ws.bill_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        CASE
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_estimate_band
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_sales,
    ss.total_orders,
    ss.average_order_value,
    CASE
        WHEN ss.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM
    customer_info ci
LEFT JOIN
    sales_summary ss ON ci.c_customer_sk = ss.bill_customer_sk
WHERE
    (ss.total_sales IS NOT NULL AND ss.total_sales > 500) OR 
    (ss.total_orders IS NULL) 
ORDER BY
    ss.average_order_value DESC NULLS LAST;
