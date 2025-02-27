
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY
        ws.ws_item_sk
),
TopItems AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        ss.total_sales,
        ss.total_quantity,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS rank
    FROM
        item i
    JOIN
        SalesSummary ss ON i.i_item_sk = ss.ws_item_sk
)
SELECT
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ti.i_product_name,
    ti.total_sales,
    ti.total_quantity
FROM
    CustomerStats cs
JOIN
    TopItems ti ON cs.c_customer_sk = (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_product_name = ti.i_product_name) LIMIT 1)
WHERE
    cs.purchase_rank <= 5 AND
    (cs.cd_gender = 'M' OR cs.cd_marital_status = 'M')
ORDER BY
    total_sales DESC
LIMIT 100
OFFSET 0;
