
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),

CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_qty,
        COALESCE(SUM(wr_return_amt), 0) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),

ReturnRatio AS (
    SELECT 
        rs.ws_item_sk,
        CASE 
            WHEN cr.total_return_qty IS NULL OR SUM(ws_quantity) = 0 THEN 0
            ELSE CAST(cr.total_return_qty AS DECIMAL(10,2)) / SUM(ws_quantity) 
        END AS return_ratio
    FROM 
        RankedSales rs
    LEFT JOIN 
        web_sales ws ON rs.ws_item_sk = ws.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.wr_item_sk
    GROUP BY 
        rs.ws_item_sk, cr.total_return_qty
),

FinalSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        COALESCE(r.return_ratio, 0) AS return_ratio
    FROM 
        RankedSales rs
    LEFT JOIN 
        ReturnRatio r ON rs.ws_item_sk = r.ws_item_sk
    WHERE rs.rn = 1
)

SELECT 
    fs.ws_item_sk,
    fs.ws_sales_price,
    CASE 
        WHEN fs.return_ratio > 0.5 THEN 'High Return'
        WHEN fs.return_ratio BETWEEN 0.1 AND 0.5 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category,
    (fs.ws_sales_price * (1 - fs.return_ratio)) AS adjusted_price
FROM 
    FinalSales fs
WHERE 
    EXISTS (
        SELECT 1 
        FROM date_dim dd 
        WHERE dd.d_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales WHERE ws_item_sk = fs.ws_item_sk) 
        AND dd.d_year = 2023
    )
ORDER BY 
    fs.ws_sales_price DESC, 
    return_category, 
    fs.ws_item_sk;
