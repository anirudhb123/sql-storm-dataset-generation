
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY c.c_customer_sk) AS rn
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddresses AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM
        customer_address ca
),
SalesData AS (
    SELECT
        ws.ws_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    GROUP BY
        ws.ws_customer_sk
),
CombinedData AS (
    SELECT
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        ca.full_address,
        sd.total_spent,
        sd.order_count
    FROM
        RankedCustomers rc
    LEFT JOIN
        CustomerAddresses ca ON rc.c_customer_sk = ca.ca_address_sk
    LEFT JOIN
        SalesData sd ON rc.c_customer_sk = sd.ws_customer_sk
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.full_address,
    COALESCE(cd.total_spent, 0) AS total_spent,
    cd.order_count
FROM
    CombinedData cd
WHERE
    cd.rn <= 5 AND
    cd.cd_gender = 'F' AND
    cd.total_spent > 100
ORDER BY
    cd.total_spent DESC;
