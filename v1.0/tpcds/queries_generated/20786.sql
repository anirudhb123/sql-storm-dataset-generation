
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_paid,
        ws_web_page_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20230101 AND 20231231
), 
return_data AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS order_count
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY wr_item_sk
), 
item_inventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    WHERE inv_date_sk = 20230101
    GROUP BY inv_item_sk
), 
customer_counts AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    i.i_item_desc,
    COALESCE(s.total_returned, 0) AS total_returned,
    COALESCE(s.total_return_amt, 0) AS total_return_amt,
    COALESCE(inv.total_inventory, 0) AS total_inventory,
    SUM(c.order_count) AS order_count,
    MIN(CASE WHEN c.order_count > 0 THEN c.order_count END) AS first_order_count,
    AVG(CASE WHEN c.return_count IS NOT NULL THEN c.return_count ELSE NULL END) AS avg_return_count
FROM 
    item i
LEFT JOIN return_data s ON i.i_item_sk = s.wr_item_sk
LEFT JOIN item_inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN customer_counts c ON i.i_item_sk = (
    SELECT ws_item_sk 
    FROM web_sales 
    WHERE ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer)
    ORDER BY ws_sold_date_sk
    LIMIT 1
)
WHERE 
    i.i_rec_start_date IS NOT NULL
GROUP BY 
    i.i_item_desc, s.total_returned, s.total_return_amt, inv.total_inventory
ORDER BY 
    first_order_count DESC, total_return_amt DESC
FETCH FIRST 100 ROWS ONLY;
