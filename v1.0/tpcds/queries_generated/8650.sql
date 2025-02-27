
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451230 AND 2451235
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_sales, 
        total_discount,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
    WHERE total_quantity > 100
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.total_discount,
    ti.sales_rank,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city
FROM TopItems ti
JOIN item i ON ti.ws_item_sk = i.i_item_sk
JOIN web_site w ON w.web_site_sk = (
    SELECT ws.web_site_sk FROM web_sales ws WHERE ws.ws_item_sk = ti.ws_item_sk LIMIT 1
)
JOIN customer c ON c.c_customer_sk = (
    SELECT ws.ws_ship_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = ti.ws_item_sk LIMIT 1
)
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE ti.sales_rank <= 10
ORDER BY ti.total_sales DESC;
