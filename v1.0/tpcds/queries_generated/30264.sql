
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, 
           i_item_id, 
           i_item_desc, 
           i_current_price, 
           i_wholesale_cost
    FROM item
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE)
    UNION ALL
    SELECT i.item_sk, 
           i.item_id, 
           i.item_desc, 
           i.current_price, 
           i.wholesale_cost
    FROM item i
    INNER JOIN ItemHierarchy ih ON i.item_sk = ih.i_item_sk -- Example recursive join for illustrative purposes
),
ItemSales AS (
    SELECT ws.ws_item_sk AS item_sk, 
           SUM(ws.ws_quantity) AS total_sales_quantity,
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim) 
    GROUP BY ws.ws_item_sk
),
SalesWithInventory AS (
    SELECT ih.i_item_id,
           ih.i_item_desc,
           COALESCE(is.total_sales_quantity, 0) AS total_sales_qty,
           COALESCE(is.total_sales_amount, 0) AS total_sales_amt,
           (SELECT SUM(inv.inv_quantity_on_hand)
            FROM inventory inv 
            WHERE inv.inv_item_sk = ih.i_item_sk) AS inventory_on_hand
    FROM ItemHierarchy ih
    LEFT JOIN ItemSales is ON ih.i_item_sk = is.item_sk
),
RankedSales AS (
    SELECT *,
           RANK() OVER (ORDER BY total_sales_amt DESC) AS sales_rank
    FROM SalesWithInventory
)
SELECT s.i_item_id, 
       s.i_item_desc, 
       COALESCE(s.total_sales_qty, 0) AS total_sales_qty, 
       COALESCE(s.total_sales_amt, 0) AS total_sales_amt,
       s.inventory_on_hand,
       CASE 
           WHEN s.total_sales_qty IS NULL THEN 'No Sales'
           WHEN s.inventory_on_hand < 10 THEN 'Low Stock'
           ELSE 'In Stock'
       END AS stock_status
FROM RankedSales s
WHERE s.sales_rank <= 10
ORDER BY s.sales_rank;
