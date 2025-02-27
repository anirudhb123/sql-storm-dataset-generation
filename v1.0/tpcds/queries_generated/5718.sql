
WITH sales_summary AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        w.web_close_date_sk IS NULL 
        AND ws.ws_ship_date_sk IS NOT NULL
        AND i.i_current_price > 0
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT
        item_sk,
        RANK() OVER (ORDER BY total_sales DESC) AS item_rank
    FROM (
        SELECT
            ws_item_sk,
            SUM(total_sales) AS total_sales
        FROM
            sales_summary
        GROUP BY
            ws_item_sk
    ) t
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ss.total_orders,
    wi.warehouse_name,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_date AS sales_date
FROM
    sales_summary ss
JOIN
    top_items ti ON ss.ws_item_sk = ti.item_sk
JOIN
    item i ON ss.ws_item_sk = i.i_item_sk
JOIN
    warehouse wi ON i.i_wholesale_cost IS NOT NULL
JOIN
    customer c ON ss.ws_bill_customer_sk = c.c_customer_sk
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN
    date_dim d ON ss.ws_sold_date_sk = d.d_date_sk
WHERE
    ti.item_rank <= 10
    AND d.d_year BETWEEN 2022 AND 2023
ORDER BY
    ss.total_sales DESC;
