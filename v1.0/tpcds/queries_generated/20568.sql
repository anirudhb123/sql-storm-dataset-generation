
WITH ranked_sales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS rn
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
high_profit_customers AS (
    SELECT
        customer_id,
        c_first_name,
        c_last_name,
        total_profit
    FROM
        ranked_sales
    WHERE
        rn = 1 AND total_profit > (
            SELECT AVG(total_profit)
            FROM ranked_sales
        )
),
items_with_sales AS (
    SELECT
        i.i_item_id,
        COUNT(ws.ws_order_number) AS sales_count,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_id
),
top_selling_items AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        ts.total_sales,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS item_rank
    FROM
        items_with_sales ts
    JOIN
        item i ON ts.i_item_id = i.i_item_id
    WHERE
        ts.sales_count > (
            SELECT AVG(sales_count) FROM items_with_sales
        )
)
SELECT
    hpc.customer_id,
    hpc.c_first_name,
    hpc.c_last_name,
    tsi.i_item_id,
    tsi.i_product_name,
    tsi.total_sales
FROM
    high_profit_customers hpc
CROSS JOIN
    top_selling_items tsi
LEFT JOIN
    customer_demographics cd ON hpc.customer_id = cd.cd_demo_sk
WHERE
    (cd.cd_credit_rating LIKE 'Excellent' OR cd.cd_marital_status IS NULL)
    AND tsi.item_rank <= 5
ORDER BY
    hpc.total_profit DESC,
    tsi.total_sales DESC;

