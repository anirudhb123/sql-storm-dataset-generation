
WITH CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
    UNION ALL
    SELECT
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_orders
    FROM
        store_sales
    GROUP BY
        ss_customer_sk
),
CombinedData AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM
        CustomerInfo AS ci
    LEFT JOIN
        SalesData AS sd ON ci.c_customer_sk = sd.ws_bill_customer_sk OR ci.c_customer_sk = sd.ss_customer_sk
)
SELECT
    ca_state,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    AVG(total_orders) AS avg_orders,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM
    CombinedData
GROUP BY
    ca_state
ORDER BY
    ca_state;
