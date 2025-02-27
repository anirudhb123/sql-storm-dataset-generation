
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        wd.warehouse_name,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS row_num
    FROM web_sales AS ws
    JOIN warehouse AS wd ON ws.ws_warehouse_sk = wd.w_warehouse_sk
),
ItemSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT sd.ws_sold_date_sk) AS sales_days
    FROM SalesData AS sd
    WHERE sd.row_num = 1
    GROUP BY sd.ws_item_sk
),
TopItems AS (
    SELECT 
        is.ws_item_sk,
        is.total_quantity,
        is.total_revenue,
        RANK() OVER (ORDER BY is.total_revenue DESC) AS revenue_rank
    FROM ItemSales AS is
    WHERE is.sales_days > 5
)
SELECT 
    ti.ws_item_sk,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_revenue,
    CASE 
        WHEN ti.revenue_rank <= 10 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_status
FROM TopItems AS ti
JOIN item AS i ON ti.ws_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT 
        ir.ws_item_sk,
        COUNT(ir.ws_order_number) AS returns_count,
        SUM(ir.ws_return_amt) AS total_returns
    FROM web_returns AS ir
    GROUP BY ir.ws_item_sk
) AS r ON ti.ws_item_sk = r.ws_item_sk
WHERE 
    r.returns_count IS NULL OR r.total_returns < 1000
ORDER BY ti.total_revenue DESC;
