
WITH RankedSales AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_net_profit DESC) AS item_rank,
        SUM(cs_quantity) OVER (PARTITION BY cs_item_sk) AS total_quantity_sold,
        SUM(cs_net_paid) OVER (PARTITION BY cs_item_sk) AS total_revenue,
        COUNT(DISTINCT cs_bill_customer_sk) OVER (PARTITION BY cs_item_sk) AS unique_customers
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) - 30 AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
),
TopSales AS (
    SELECT
        cs.item_sk,
        cs.order_number,
        cs.net_profit,
        cs.quantity,
        COALESCE(c.c_first_name, 'Unknown') AS customer_first_name,
        COALESCE(c.c_last_name, 'Unknown') AS customer_last_name,
        i.i_item_desc,
        RANK() OVER (ORDER BY cs.net_profit DESC) AS profit_rank
    FROM
        catalog_sales cs
    JOIN
        item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE
        cs_quantity > 0
)
SELECT
    t.item_sk,
    t.order_number,
    t.net_profit,
    COALESCE(t.customer_first_name, 'N/A') AS first_name,
    COALESCE(t.customer_last_name, 'N/A') AS last_name,
    t.quantity,
    CASE
        WHEN t.net_profit > 0 THEN 'Profitable'
        WHEN t.net_profit < 0 THEN 'Loss'
        ELSE 'Break Even'
    END AS profit_status,
    r.total_quantity_sold,
    r.total_revenue,
    r.unique_customers
FROM
    TopSales t
JOIN
    RankedSales r ON t.cs_item_sk = r.cs_item_sk
WHERE
    r.item_rank = 1
ORDER BY
    t.net_profit DESC,
    t.order_number ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
