
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS ranking
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        RankedCustomers c
    WHERE
        c.ranking <= 5
)
SELECT
    fc.full_name,
    fc.cd_gender,
    fc.cd_marital_status,
    fc.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent
FROM
    FilteredCustomers fc
LEFT JOIN
    web_sales ws ON fc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY
    fc.full_name, fc.cd_gender, fc.cd_marital_status, fc.cd_education_status
ORDER BY
    total_spent DESC
LIMIT 10;
