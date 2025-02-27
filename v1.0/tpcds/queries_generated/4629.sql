
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_quantity) DESC) AS site_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws.web_site_sk, ws.ws_order_number, ws_item_sk
),
TopItems AS (
    SELECT
        ri.web_site_sk,
        ri.ws_item_sk,
        ri.total_quantity
    FROM
        RankedSales ri
    WHERE
        ri.site_rank <= 10
),
ItemDetails AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(c.c_customer_id, 'Unknown') AS customer_id,
        COALESCE(c.c_first_name, 'N/A') AS customer_first_name,
        COALESCE(c.c_last_name, 'N/A') AS customer_last_name
    FROM
        item i
    LEFT JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
)
SELECT
    itd.customer_id,
    itd.customer_first_name,
    itd.customer_last_name,
    ti.ws_item_sk,
    ti.total_quantity,
    itd.i_item_desc,
    itd.i_current_price,
    ti.total_quantity * itd.i_current_price AS total_revenue,
    CASE 
        WHEN ti.total_quantity > 100 THEN 'High Volume'
        WHEN ti.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM
    TopItems ti
JOIN
    ItemDetails itd ON ti.ws_item_sk = itd.i_item_sk
ORDER BY
    total_revenue DESC
LIMIT 50;
