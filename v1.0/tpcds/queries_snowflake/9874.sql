
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_profit DESC) AS rank_profit
    FROM catalog_sales cs
    INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20.00
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(rank_sales.cs_quantity) AS total_sold,
        SUM(rank_sales.cs_net_profit) AS total_profit
    FROM RankedSales rank_sales
    JOIN item ON rank_sales.cs_item_sk = item.i_item_sk
    WHERE rank_sales.rank_profit <= 10
    GROUP BY item.i_item_id, item.i_product_name
)
SELECT 
    item.i_item_id AS "Item ID",
    item.i_product_name AS "Product Name",
    sales.total_sold AS "Total Quantity Sold",
    sales.total_profit AS "Total Profit",
    (SELECT COUNT(DISTINCT ws.ws_bill_customer_sk)
     FROM web_sales ws
     WHERE ws.ws_item_sk = item.i_item_sk) AS "Unique Customers"
FROM TopSales sales
JOIN item ON sales.i_item_id = item.i_item_id
ORDER BY sales.total_profit DESC
LIMIT 100;
