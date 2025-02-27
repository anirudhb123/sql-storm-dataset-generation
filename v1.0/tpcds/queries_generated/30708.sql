
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450905 AND 2450911  -- Example date range
    GROUP BY ws_item_sk
), High_Sellers AS (
    SELECT 
        w.warehouse_id,
        w.warehouse_name,
        c.c_first_name,
        c.c_last_name,
        sc.total_quantity,
        sc.total_sales
    FROM Sales_CTE sc
    JOIN item i ON sc.ws_item_sk = i.i_item_sk
    JOIN store s ON s.s_store_sk = i.i_manager_id
    JOIN warehouse w ON w.w_warehouse_sk = s.s_store_sk
    JOIN customer c ON c.c_customer_sk = (SELECT c_customer_sk FROM web_sales WHERE ws_item_sk = sc.ws_item_sk LIMIT 1)
    WHERE sc.rank <= 10
), Total_Sales AS (
    SELECT 
        SUM(total_sales) AS overall_sales,
        SUM(total_quantity) AS overall_quantity
    FROM High_Sellers
)
SELECT 
    hs.warehouse_id, 
    hs.warehouse_name, 
    CONCAT(hs.c_first_name, ' ', hs.c_last_name) AS customer_name,
    hs.total_quantity,
    hs.total_sales,
    ts.overall_sales,
    ts.overall_quantity
FROM High_Sellers hs
JOIN Total_Sales ts ON 1=1
ORDER BY hs.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
