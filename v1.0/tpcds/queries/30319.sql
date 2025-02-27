
WITH RECURSIVE revenue_data AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM
        web_sales
    WHERE
        ws_sales_price > 0
), total_revenue AS (
    SELECT
        rd.ws_order_number,
        SUM(rd.ws_ext_sales_price) AS total_sales,
        COUNT(rd.ws_item_sk) AS item_count
    FROM
        revenue_data rd
    GROUP BY
        rd.ws_order_number
), high_quantity_orders AS (
    SELECT
        tr.ws_order_number,
        tr.total_sales,
        tr.item_count
    FROM
        total_revenue tr
    WHERE
        tr.item_count > 5
), customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), final_report AS (
    SELECT
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.purchase_category,
        hqo.total_sales,
        hqo.item_count,
        RANK() OVER (ORDER BY hqo.total_sales DESC) AS sales_rank
    FROM
        high_quantity_orders hqo
    JOIN
        customer_info ci ON ci.c_customer_sk IN (
            SELECT 
                ws_bill_customer_sk
            FROM
                web_sales
            WHERE
                ws_order_number = hqo.ws_order_number
        )
)
SELECT
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.purchase_category,
    fr.total_sales,
    fr.item_count,
    fr.sales_rank
FROM
    final_report fr
WHERE
    fr.sales_rank <= 10
ORDER BY
    fr.total_sales DESC;
