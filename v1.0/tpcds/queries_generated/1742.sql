
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        COALESCE(sr.sr_return_quantity, 0) AS return_quantity,
        COALESCE(sr.sr_return_amt, 0) AS return_amt,
        COALESCE(sr.sr_return_tax, 0) AS return_tax,
        (ws.ws_sales_price * ws.ws_quantity) - 
        COALESCE(sr.sr_return_amt, 0) AS net_sales
    FROM web_sales ws
    LEFT JOIN store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_order_number
)
, RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(net_sales) AS total_net_sales,
        RANK() OVER (ORDER BY SUM(net_sales) DESC) AS sales_rank
    FROM SalesData
    GROUP BY ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    rs.total_net_sales,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS sales_category,
    (SELECT COUNT(DISTINCT cc.cc_call_center_sk) FROM call_center cc 
     INNER JOIN store s ON s.s_store_sk = cc.cc_call_center_sk 
     WHERE s.s_city = 'Los Angeles') AS cc_count
FROM RankedSales rs
JOIN item i ON rs.ws_item_sk = i.i_item_sk
WHERE rs.total_net_sales > 0
AND EXISTS (
    SELECT 1 
    FROM customer c 
    WHERE c.c_current_addr_sk IS NOT NULL AND c.c_customer_sk IN (
        SELECT sr.sr_customer_sk 
        FROM store_returns sr 
        WHERE sr.sr_return_quantity > 0
    )
)
ORDER BY rs.total_net_sales DESC
