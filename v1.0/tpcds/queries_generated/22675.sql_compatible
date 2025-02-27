
WITH RankedSales AS (
    SELECT 
        s_item_sk, 
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_item_sk ORDER BY SUM(ss_sales_price) DESC) AS rank_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        s_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.s_item_sk,
        rs.total_sales,
        i.i_item_desc
    FROM 
        RankedSales rs 
    JOIN 
        item i ON rs.s_item_sk = i.i_item_sk
    WHERE 
        rs.rank_sales <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_qty) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesReturnRatio AS (
    SELECT 
        tsi.i_item_desc,
        tsi.total_sales,
        cr.total_returns,
        cr.total_return_amount,
        CASE 
            WHEN cr.total_returns IS NULL OR cr.total_returns = 0 THEN 0 
            ELSE ROUND(tsi.total_sales / cr.total_returns, 2) 
        END AS sales_to_return_ratio
    FROM 
        TopSellingItems tsi
    LEFT JOIN 
        CustomerReturns cr ON tsi.s_item_sk = cr.sr_item_sk
)
SELECT 
    srr.i_item_desc,
    srr.total_sales,
    srr.total_returns,
    srr.total_return_amount,
    srr.sales_to_return_ratio,
    CASE 
        WHEN srr.sales_to_return_ratio IS NULL THEN 'N/A'
        WHEN srr.sales_to_return_ratio >= 10 THEN 'Excellent'
        WHEN srr.sales_to_return_ratio >= 5 THEN 'Good'
        WHEN srr.sales_to_return_ratio >= 2 THEN 'Average'
        ELSE 'Poor' 
    END AS performance_rating
FROM 
    SalesReturnRatio srr
ORDER BY 
    srr.total_sales DESC, srr.sales_to_return_ratio ASC;
