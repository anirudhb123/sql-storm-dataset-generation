
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
top_items AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM
        ranked_sales rs
    JOIN
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE
        rs.sales_rank <= 10
),
customer_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_customer_sales
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_id
),
customer_demographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cs.c_customer_id) AS customer_count,
        SUM(cs.total_customer_sales) AS total_sales
    FROM
        customer_sales cs
    JOIN
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
)
SELECT
    t_item.i_item_id,
    t_item.i_item_desc,
    cdem.cd_gender,
    cdem.cd_marital_status,
    cdem.customer_count,
    cdem.total_sales
FROM
    top_items t_item
JOIN
    customer_demographics cdem ON t_item.total_sales > cdem.total_sales
ORDER BY
    total_quantity DESC, total_sales DESC;
