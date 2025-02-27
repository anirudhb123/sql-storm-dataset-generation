
WITH RECURSIVE sales_data AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        (ws.ws_quantity * ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
customer_returns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        (CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN' 
            ELSE CASE 
                WHEN cd.cd_purchase_estimate < 1000 THEN 'LOW'
                WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'MEDIUM'
                ELSE 'HIGH' 
            END 
        END) AS purchase_band
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
final_sales AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.total_sales) AS total_sales,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        ci.purchase_band
    FROM
        sales_data sd
    LEFT JOIN 
        customer_returns cr ON sd.ws_item_sk = cr.cr_item_sk
    JOIN 
        customer_info ci ON sd.ws_order_number = (SELECT ws.ws_order_number FROM web_sales ws WHERE ws.ws_item_sk = sd.ws_item_sk LIMIT 1)
    GROUP BY
        sd.ws_item_sk, ci.purchase_band
)
SELECT
    fs.ws_item_sk,
    fs.total_sales,
    fs.total_return_quantity,
    fs.total_return_amount,
    ROUND((fs.total_sales - fs.total_return_amount), 2) AS net_sales,
    fs.purchase_band,
    CASE 
        WHEN fs.total_sales > 10000 THEN 'HIGH PERFORMER'
        WHEN fs.total_sales BETWEEN 5000 AND 10000 THEN 'MEDIUM PERFORMER'
        ELSE 'LOW PERFORMER'
    END AS performance_category
FROM
    final_sales fs
ORDER BY
    net_sales DESC, fs.ws_item_sk
LIMIT 100;
