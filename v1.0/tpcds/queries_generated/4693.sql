
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        AVG(ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_sales_price,
        sales.average_profit,
        sales.total_orders,
        RANK() OVER (ORDER BY sales.total_quantity DESC) AS rank
    FROM 
        SalesData sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.total_quantity > 0
        AND item.i_rec_start_date <= CURRENT_DATE
        AND (item.i_rec_end_date IS NULL OR item.i_rec_end_date > CURRENT_DATE)
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_sales_price,
    tsi.average_profit,
    tsi.total_orders,
    CASE 
        WHEN tsi.rank <= 10 THEN 'Top Seller'
        ELSE 'Regular'
    END AS sales_category
FROM 
    TopSellingItems tsi
LEFT JOIN 
    (SELECT DISTINCT ca_state, ca_country 
     FROM customer_address 
     WHERE ca_country IS NOT NULL) addr ON 1=1
WHERE 
    tsi.rank <= 10 OR (tsi.rank > 10 AND tsi.total_sales_price > 1000)
ORDER BY 
    tsi.rank
UNION ALL
SELECT 
    'Total',
    NULL,
    SUM(tsi.total_quantity),
    SUM(tsi.total_sales_price),
    AVG(tsi.average_profit), 
    SUM(tsi.total_orders),
    'Total Sales'
FROM 
    TopSellingItems tsi
HAVING 
    COUNT(*) > 0;
