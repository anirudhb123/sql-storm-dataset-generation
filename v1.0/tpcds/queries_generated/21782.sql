
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity, 
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(rs.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(rs.ws_sales_price * rs.ws_quantity), 0) AS total_sales
    FROM 
        item i
    LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    GROUP BY 
        i.i_item_id
),
TopSales AS (
    SELECT 
        item_id,
        total_quantity,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
    WHERE 
        total_sales IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    tp.item_id,
    tp.total_quantity,
    tp.total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.return_amount, 0) AS return_amount,
    CASE 
        WHEN tp.total_sales IS NULL THEN 'No Sales'
        ELSE CAST(tp.total_sales AS VARCHAR) || ' USD'
    END AS formatted_sales,
    CASE 
        WHEN tp.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category
FROM 
    TopSales tp
LEFT JOIN CustomerReturns cr ON tp.item_id = cr.sr_item_sk
WHERE 
    tp.total_quantity > (SELECT AVG(total_quantity) FROM SalesSummary)
    AND tp.total_sales IS NOT NULL OR tp.sales_rank IS NULL
ORDER BY 
    formatted_sales DESC, total_sales ASC
FETCH FIRST 100 ROWS ONLY;
