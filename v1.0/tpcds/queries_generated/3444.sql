
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn,
        ws_quantity,
        ws_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
SalesSummary AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        SUM(RankedSales.ws_quantity) AS total_units_sold,
        SUM(RankedSales.ws_sales_price * RankedSales.ws_quantity) AS total_revenue,
        COUNT(DISTINCT RankedSales.ws_order_number) AS total_orders
    FROM RankedSales
    JOIN item ON RankedSales.ws_item_sk = item.i_item_sk
    GROUP BY item.i_item_id, item.i_item_desc
),
TopSellingItems AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM SalesSummary
)
SELECT 
    COALESCE(customer.c_first_name, 'Unknown') AS first_name,
    COALESCE(customer.c_last_name, 'Unknown') AS last_name,
    top_items.i_item_id,
    top_items.i_item_desc,
    top_items.total_units_sold,
    top_items.total_revenue
FROM TopSellingItems top_items
LEFT JOIN customer ON top_items.total_orders > 50 AND customer.c_customer_sk = (
    SELECT ws_bill_customer_sk
    FROM web_sales
    WHERE ws_sales_price = (
        SELECT MAX(ws_sales_price)
        FROM web_sales
        WHERE ws_item_sk = top_items.i_item_id
    )
    LIMIT 1
)
WHERE top_items.revenue_rank <= 10
ORDER BY top_items.total_revenue DESC;

