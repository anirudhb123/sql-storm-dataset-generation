
WITH ranked_sales AS (
    SELECT
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        cs_item_sk
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year >= 1990
    GROUP BY
        c.c_customer_sk, c.c_gender
),
inventory_stock AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock,
        (
            SELECT COALESCE(SUM(ws.ws_net_profit), 0)
            FROM web_sales ws
            WHERE ws.ws_item_sk = inv.inv_item_sk
        ) AS total_sales_value
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
)
SELECT
    ca.ca_city,
    ISNULL(sales.total_sales, 0) AS total_sales_value,
    inv.total_stock,
    cs.total_orders,
    cs.total_profit
FROM
    customer_address ca
LEFT JOIN
    ranked_sales sales ON sales.cs_item_sk IN (
        SELECT i.i_item_sk
        FROM item i
        WHERE i.i_class = 'Beverages'
    )
FULL OUTER JOIN
    inventory_stock inv ON inv.inv_item_sk = sales.cs_item_sk
LEFT JOIN
    customer_summary cs ON cs.c_customer_sk = inv.inv_item_sk
WHERE
    ca.ca_state = 'CA'
    AND (sales.total_sales IS NOT NULL OR inv.total_stock > 0)
ORDER BY
    ca.ca_city,
    total_sales_value DESC;
