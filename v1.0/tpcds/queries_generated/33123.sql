
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
),
ItemDetails AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_current_price
    FROM item
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE)
),
CustomerSales AS (
    SELECT c.c_customer_id, SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT c_customer_id, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) as rank
    FROM CustomerSales
)
SELECT 
    t.customer_id,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(i.i_product_name, 'Unknown') AS product_name,
    SUM(s.ws_sales_price * s.ws_quantity) OVER (PARTITION BY t.customer_id) AS total_spent,
    CASE 
        WHEN t.total_sales > 1000 THEN 'High Value'
        WHEN t.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM TopCustomers t
LEFT JOIN SalesCTE s ON t.c_customer_id = (SELECT c.c_customer_id 
                                            FROM customer c 
                                            WHERE c.c_customer_sk = s.ws_ship_customer_sk)
LEFT JOIN ItemDetails i ON s.ws_item_sk = i.i_item_sk
WHERE t.rank <= 10
ORDER BY total_spent DESC
LIMIT 100;
