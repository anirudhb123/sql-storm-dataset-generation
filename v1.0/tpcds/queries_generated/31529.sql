
WITH RECURSIVE Sales_CTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        1 AS level
    FROM
        web_sales
    GROUP BY
        ws_item_sk

    UNION ALL

    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid,
        level + 1
    FROM
        catalog_sales
    WHERE
        level < 3
    GROUP BY
        cs_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_quantity, 0) AS total_quantity_sold,
    COALESCE(s.total_net_paid, 0) AS total_net_paid_collected,
    d.d_month AS sales_month,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    RANK() OVER (PARTITION BY d.d_month ORDER BY COALESCE(s.total_net_paid, 0) DESC) AS sales_rank
FROM
    item i
LEFT JOIN
    Sales_CTE s ON i.i_item_sk = s.ws_item_sk OR i.i_item_sk = s.cs_item_sk
LEFT JOIN
    date_dim d ON d.d_date_sk = ws_sold_date_sk
LEFT JOIN
    customer c ON c.c_customer_sk = s.ws_bill_customer_sk OR c.c_customer_sk = s.cs_bill_customer_sk
WHERE
    i.i_current_price > 20
    AND d.d_year = 2023
    AND (s.total_quantity IS NULL OR s.total_net_paid > 100)
GROUP BY
    i.i_item_id, i.i_item_desc, sales_month
HAVING
    COALESCE(total_quantity_sold, 0) > 10
ORDER BY
    sales_rank;
