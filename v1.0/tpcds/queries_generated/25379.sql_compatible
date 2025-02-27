
WITH CustomerInfo AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        cd.cd_gender = 'F'
),
SalesInfo AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_sales,
        CASE
            WHEN si.total_sales >= 1000 THEN 'High'
            WHEN si.total_sales BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM
        CustomerInfo ci
    LEFT JOIN
        SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    total_sales,
    sales_category
FROM
    FinalReport
ORDER BY
    total_sales DESC
LIMIT 100;
