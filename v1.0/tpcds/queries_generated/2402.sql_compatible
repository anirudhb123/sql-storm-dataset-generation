
WITH ItemSales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        AVG(ws_net_paid) AS avg_sale_amount 
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
ReturnStats AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns 
    GROUP BY 
        wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        is.ws_item_sk,
        is.total_orders,
        is.total_sales,
        is.avg_sale_amount,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount
    FROM 
        ItemSales is
    LEFT JOIN 
        ReturnStats rs ON is.ws_item_sk = rs.wr_item_sk
),
SalesRanked AS (
    SELECT 
        swr.*,
        RANK() OVER (ORDER BY swr.total_sales DESC) AS sales_rank
    FROM 
        SalesWithReturns swr
)
SELECT 
    s.ws_item_sk,
    i.i_item_desc,
    s.total_orders,
    s.total_sales,
    s.avg_sale_amount,
    s.total_returns,
    s.total_return_amount,
    s.sales_rank,
    CASE 
        WHEN s.total_sales > 5000 THEN 'High Performer'
        WHEN s.total_sales BETWEEN 1000 AND 5000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    SalesRanked s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
WHERE 
    s.sales_rank <= 10
ORDER BY 
    s.sales_rank;
