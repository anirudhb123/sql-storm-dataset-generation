
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_brand, i_current_price, 1 AS level
    FROM item
    WHERE i_current_price > (
        SELECT AVG(i_current_price)
        FROM item
    )
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_brand, i.i_current_price, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_current_price < ih.i_current_price
),
SalesData AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023
        AND d.d_month_seq BETWEEN 1 AND 6
    )
    GROUP BY ws.ws_item_sk
),
CustomerWithSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, coalesce(sd.total_quantity, 0) AS total_quantity, coalesce(sd.total_sales, 0) AS total_sales
    FROM customer c
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_item_sk
)
SELECT ih.i_item_id, ih.i_item_desc, ih.i_brand, c.first_last_name,
    c.total_quantity, c.total_sales,
    ROW_NUMBER() OVER (PARTITION BY ih.i_item_id ORDER BY c.total_sales DESC) AS sales_rank
FROM ItemHierarchy ih
JOIN CustomerWithSales c ON ih.i_item_sk = c.c_customer_sk
WHERE ih.level <= 3 AND (c.total_quantity > 0 OR c.total_sales > 0)
ORDER BY ih.i_item_id, sales_rank;
