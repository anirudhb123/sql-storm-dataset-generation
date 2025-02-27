
WITH RECURSIVE sales_data AS (
    SELECT
        ws_ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
date_range AS (
    SELECT
        d_date_sk,
        d_year,
        d_month_seq
    FROM
        date_dim
    WHERE
        d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
customer_rank AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_purchase_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
store_performance AS (
    SELECT
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM
        store s
    LEFT JOIN
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY
        s.s_store_sk
)
SELECT
    ca.ca_city,
    SUM(sd.total_sales) AS total_sales,
    AVG(sp.avg_sales_price) AS average_sales_price,
    AVG(cd.cd_purchase_estimate) AS avg_customer_purchase_estimate,
    MAX(cr.gender_purchase_rank) AS max_gender_purchase_rank
FROM
    sales_data sd
JOIN
    date_range dr ON sd.ws_ws_sold_date_sk = dr.d_date_sk
JOIN
    customer_rank cr ON cr.c_customer_sk IN (
        SELECT
            ws_bill_customer_sk FROM web_sales
        WHERE
            ws_item_sk = sd.ws_item_sk
    )
JOIN
    store_performance sp ON sp.s_store_sk = (
        SELECT ss_store_sk
        FROM store_sales
        WHERE ss_item_sk = sd.ws_item_sk LIMIT 1
    )
JOIN
    customer_address ca ON ca.ca_address_sk = (
        SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cr.c_customer_sk LIMIT 1
    )
GROUP BY
    ca.ca_city
HAVING
    COUNT(DISTINCT cr.c_customer_sk) > 10
ORDER BY
    total_sales DESC
LIMIT 100;
