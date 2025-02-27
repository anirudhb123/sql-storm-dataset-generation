
WITH sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws_item_sk
),
top_items AS (
    SELECT
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_orders,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
    FROM
        sales_data sd
),
item_details AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        ti.total_sales,
        ti.total_orders
    FROM
        item i
    JOIN
        top_items ti ON i.i_item_sk = ti.ws_item_sk
    WHERE
        ti.rank <= 10
)
SELECT
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    id.i_brand,
    id.total_sales,
    id.total_orders,
    CASE 
        WHEN id.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status,
    COALESCE((SELECT MAX(c.cc_last_name) 
              FROM customer c 
              WHERE c.c_current_cdemo_sk IS NOT NULL 
              AND c.c_current_addr_sk IN 
                  (SELECT ca.ca_address_sk 
                   FROM customer_address ca 
                   WHERE ca.ca_city = 'New York')), 'No Customers') AS last_customer
FROM
    item_details id
ORDER BY
    id.total_sales DESC;
