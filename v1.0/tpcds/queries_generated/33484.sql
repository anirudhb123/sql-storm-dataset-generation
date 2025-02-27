
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    HAVING SUM(ws_net_profit) > 0
),
AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM customer_address
    JOIN customer ON ca_address_sk = c_current_addr_sk
    GROUP BY ca_state
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_sales,
        RANK() OVER (ORDER BY COALESCE(SUM(ws_ext_sales_price), 0) DESC) AS sales_rank
    FROM item
    LEFT JOIN web_sales ON item.i_item_sk = web_sales.ws_item_sk
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY item.i_item_id, item.i_item_desc
)
SELECT 
    a.ca_state,
    a.customer_count,
    COALESCE(s.total_sales, 0) AS total_sales,
    a.avg_gmt_offset,
    CASE 
        WHEN a.customer_count > 100 THEN 'High'
        WHEN a.customer_count BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS customer_segment,
    COALESCE(sales.total_quantity, 0) AS cumulative_quantity
FROM AddressStats a
LEFT JOIN TopSales s ON a.ca_state = 'NY'  -- Arbitrary choice for comparison
LEFT JOIN SalesCTE sales ON sales.ws_item_sk = s.i_item_sk AND sales.rnk = 1
WHERE a.avg_gmt_offset IS NOT NULL
ORDER BY a.customer_count DESC, total_sales DESC
LIMIT 10;
