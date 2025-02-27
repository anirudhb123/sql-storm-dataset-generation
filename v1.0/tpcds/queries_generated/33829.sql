
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk,
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY ws_item_sk

    UNION ALL

    SELECT cs_item_sk,
           SUM(cs_sales_price) AS total_sales,
           COUNT(cs_order_number) AS order_count
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY cs_item_sk
),
TopItems AS (
    SELECT item.i_item_sk,
           item.i_item_id,
           item.i_product_name,
           COALESCE(s.total_sales, 0) AS total_sales
    FROM item
    LEFT JOIN (
        SELECT ws_item_sk, SUM(total_sales) AS total_sales
        FROM SalesCTE
        GROUP BY ws_item_sk
        HAVING SUM(total_sales) > 1000
    ) AS s ON item.i_item_sk = s.ws_item_sk
)
SELECT T.i_item_id,
       T.i_product_name,
       T.total_sales,
       ROW_NUMBER() OVER (ORDER BY T.total_sales DESC) AS sales_rank,
       NULLIF(T.total_sales / NULLIF(SUM(T.total_sales) OVER (), 0), 0) AS sales_percentage
FROM TopItems T
ORDER BY T.total_sales DESC
LIMIT 10;

SELECT DISTINCT ca_state, COUNT(DISTINCT c_customer_sk) AS customer_count
FROM customer_address
LEFT JOIN customer ON ca_address_sk = c_current_addr_sk
WHERE COALESCE(c_preferred_cust_flag, 'N') = 'Y'
GROUP BY ca_state
HAVING COUNT(DISTINCT c_customer_sk) > 100
UNION
SELECT w_state, SUM(ws_quantity) AS total_quantity
FROM warehouse
JOIN web_sales ON w_warehouse_sk = ws_warehouse_sk
GROUP BY w_state
HAVING SUM(ws_quantity) > 500
ORDER BY 1;
