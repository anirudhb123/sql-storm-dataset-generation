
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
),
ReturnCTE AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(s.ws_sales_price * s.ws_quantity) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        (SUM(s.ws_sales_price * s.ws_quantity) - COALESCE(r.total_returns, 0)) AS net_sales
    FROM 
        SalesCTE s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        ReturnCTE r ON s.ws_item_sk = r.sr_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY net_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    rs.i_item_id,
    rs.i_item_desc,
    rs.total_sales,
    rs.total_returns,
    rs.net_sales,
    rs.sales_rank,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top Selling'
        WHEN rs.net_sales = 0 THEN 'No Sales'
        ELSE 'Average Seller'
    END AS sales_category
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 50 OR rs.total_sales = 0
ORDER BY 
    rs.sales_rank, rs.total_sales DESC;
