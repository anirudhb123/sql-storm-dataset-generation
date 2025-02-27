
WITH customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        COALESCE(ws.ws_net_profit, 0) AS net_profit,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk IS NOT NULL
    UNION ALL
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sales_price,
        COALESCE(cs.cs_net_profit, 0) AS net_profit,
        SUM(cs.cs_quantity) OVER (PARTITION BY cs.cs_item_sk) AS total_quantity_sold
    FROM
        catalog_sales cs
    WHERE
        cs.cs_ship_date_sk IS NOT NULL
),
returned_items AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_item_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    sd.ws_order_number,
    sd.ws_item_sk,
    sd.ws_sales_price,
    sd.net_profit,
    sd.total_quantity_sold,
    COALESCE(ri.total_returns, 0) AS total_returns,
    COALESCE(ri.total_return_amount, 0) AS total_return_amount,
    CASE
        WHEN nti.total_returns IS NULL THEN 'No Returns'
        WHEN nti.total_returns > 0 THEN 'Returned'
        ELSE 'Not Returned' 
    END AS return_status
FROM
    customer_info ci
LEFT JOIN sales_data sd ON sd.ws_order_number IN (
    SELECT
        ws_order_number
    FROM
        web_sales
    WHERE
        ws_bill_customer_sk = ci.c_customer_sk
) 
LEFT JOIN returned_items ri ON sd.ws_item_sk = ri.sr_item_sk
WHERE
    ci.rn = 1
AND
    (ci.cd_marital_status = 'M' OR (ci.cd_gender = 'F' AND ci.c_first_name LIKE '%A%'))
ORDER BY
    ci.c_last_name,
    ci.c_first_name,
    sd.ws_sales_price DESC;
