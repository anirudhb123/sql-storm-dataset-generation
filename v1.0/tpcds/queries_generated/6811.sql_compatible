
WITH sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2450017 AND 2450290
    GROUP BY
        ws_item_sk
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_class,
        i.i_category,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_net_profit,
        ss.order_count
    FROM
        item i
    JOIN
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
),
top_items AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        item_details
)
SELECT
    ti.i_product_name,
    ti.i_brand,
    ti.total_quantity,
    ti.total_sales,
    ti.avg_net_profit,
    ti.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_state
FROM
    top_items ti
JOIN
    web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
JOIN
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    ti.sales_rank <= 10
ORDER BY
    ti.total_sales DESC;
