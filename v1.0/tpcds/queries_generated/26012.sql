
WITH CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_street_type) AS full_address,
        inv.inv_quantity_on_hand,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_country, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, inv.inv_quantity_on_hand
),
RankedCustomers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_net_profit DESC) AS profit_rank
    FROM
        CustomerDetails
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_net_profit,
    profit_rank
FROM
    RankedCustomers
WHERE
    profit_rank <= 10
ORDER BY
    cd_gender, total_net_profit DESC;
