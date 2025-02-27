
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
),
ReturnData AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns
    GROUP BY wr_item_sk
),
CombinedData AS (
    SELECT 
        COALESCE(sd.ws_item_sk, rd.wr_item_sk) AS item_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_revenue, 0) AS total_revenue,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_value, 0) AS total_return_value
    FROM SalesData sd
    FULL OUTER JOIN ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
),
RankedData AS (
    SELECT 
        item_sk,
        total_sales,
        total_revenue,
        total_returns,
        total_return_value,
        RANK() OVER (ORDER BY total_revenue DESC, total_sales ASC) AS revenue_rank,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN total_sales = 0 THEN 'No Sales'
            WHEN total_sales > 0 AND total_sales <= 100 THEN 'Low Sales'
            WHEN total_sales > 100 AND total_sales <= 1000 THEN 'Medium Sales'
            ELSE 'High Sales' END 
            ORDER BY total_revenue DESC) AS sales_category_rank
    FROM CombinedData
),
FinalReport AS (
    SELECT 
        item_sk,
        total_sales,
        total_revenue,
        total_returns,
        total_return_value,
        revenue_rank,
        sales_category_rank,
        CASE 
            WHEN total_sales = 0 AND total_returns = 0 THEN 'No Activity'
            WHEN total_returns > total_sales THEN 'Return-Heavy'
            WHEN total_sales > total_returns THEN 'Sales-Heavy'
            ELSE 'Balanced'
        END AS activity_status
    FROM RankedData
)
SELECT 
    fr.item_sk, 
    fr.total_sales, 
    fr.total_revenue, 
    fr.total_returns, 
    fr.total_return_value, 
    fr.revenue_rank,
    fr.sales_category_rank,
    fr.activity_status,
    d.d_date AS sale_date,
    w.w_warehouse_name,
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    CASE 
        WHEN rnd.sample_id IS NOT NULL THEN 'Sample Available' 
        ELSE 'No Sample' 
    END AS sample_status
FROM FinalReport fr
LEFT JOIN date_dim d ON d.d_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales WHERE ws_item_sk = fr.item_sk)
LEFT JOIN warehouse w ON w.w_warehouse_sk = (SELECT TOP 1 ws_warehouse_sk FROM web_sales WHERE ws_item_sk = fr.item_sk ORDER BY ws_sold_date_sk DESC)
LEFT JOIN customer c ON c.c_customer_sk = (SELECT TOP 1 ws_ship_customer_sk FROM web_sales WHERE ws_item_sk = fr.item_sk ORDER BY ws_sold_date_sk DESC)
LEFT JOIN (
    SELECT 
        wr_item_sk, 
        RANK() OVER (PARTITION BY wr_item_sk ORDER BY wr_return_amt DESC) AS sample_id
    FROM web_returns
    WHERE wr_return_quantity > 0
) rnd ON rnd.wr_item_sk = fr.item_sk
WHERE fr.activity_status IN ('Sales-Heavy', 'Return-Heavy')
ORDER BY fr.revenue_rank, fr.sales_category_rank;
