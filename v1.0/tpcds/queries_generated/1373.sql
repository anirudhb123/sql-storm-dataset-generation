
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 5000 AND 6000
),
TotalReturns AS (
    SELECT 
        cr_item_sk, 
        SUM(cr_return_quantity) AS total_returned
    FROM 
        catalog_returns 
    GROUP BY 
        cr_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity_sold,
        SUM(rs.ws_net_paid) AS total_net_paid,
        COALESCE(tr.total_returned, 0) AS total_returns,
        (SUM(rs.ws_net_paid) - COALESCE(tr.total_returned * AVG(rs.ws_sales_price) OVER (PARTITION BY rs.ws_item_sk), 0)) AS net_revenue
    FROM 
        RankedSales rs
    LEFT JOIN 
        TotalReturns tr ON rs.ws_item_sk = tr.cr_item_sk
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk, tr.total_returned
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity_sold,
    ts.total_net_paid,
    ts.total_returns,
    ts.net_revenue,
    CASE 
        WHEN ts.net_revenue < 0 THEN 'Loss'
        WHEN ts.net_revenue > 0 AND ts.net_revenue <= 1000 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profitability_category
FROM 
    item i
JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk
ORDER BY 
    ts.net_revenue DESC, ts.total_quantity_sold DESC
FETCH FIRST 10 ROWS ONLY;
