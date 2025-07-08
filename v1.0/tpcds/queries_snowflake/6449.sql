
WITH sales_data AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY
        ws_sold_date_sk,
        ws_item_sk
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
inventory_data AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
)
SELECT
    s.ws_sold_date_sk,
    c.c_customer_sk,
    c.cd_gender,
    c.cd_marital_status,
    SUM(s.total_quantity) AS total_quantity_sold,
    SUM(s.total_profit) AS total_profit,
    i.total_inventory
FROM
    sales_data s
    JOIN customer_data c ON s.ws_item_sk IN (
        SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk
    )
    JOIN inventory_data i ON s.ws_item_sk = i.inv_item_sk
GROUP BY
    s.ws_sold_date_sk,
    c.c_customer_sk,
    c.cd_gender,
    c.cd_marital_status,
    i.total_inventory
ORDER BY
    s.ws_sold_date_sk,
    total_profit DESC
LIMIT 100;
