
WITH address_details AS (
    SELECT
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS customer_names,
        ca_address_sk
    FROM
        customer_address
    JOIN
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY
        ca_city,
        ca_state,
        ca_address_sk
),
sales_summary AS (
    SELECT
        ws_bill_addr_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_addr_sk
),
city_sales AS (
    SELECT
        ad.ca_city,
        ad.ca_state,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        ad.customer_count,
        ad.customer_names
    FROM
        address_details ad
    LEFT JOIN
        sales_summary ss ON ad.ca_address_sk = ss.ws_bill_addr_sk
)
SELECT
    cs.ca_city,
    cs.ca_state,
    cs.total_sales,
    cs.order_count,
    cs.customer_count,
    cs.customer_names,
    CASE
        WHEN cs.total_sales > 100000 THEN 'High Sales'
        WHEN cs.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM
    city_sales cs
ORDER BY
    cs.total_sales DESC;
