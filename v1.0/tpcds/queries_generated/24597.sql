
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
), ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        isnull(r.r_reason_desc, 'No Reason') AS return_reason,
        CASE 
            WHEN i.i_current_price IS NULL THEN 0 
            ELSE i.i_current_price 
        END AS adjusted_price
    FROM item i
    LEFT JOIN (SELECT cr_item_sk, MAX(cr_return_amount) AS max_return_amount FROM catalog_returns GROUP BY cr_item_sk) cr
        ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN reason r ON cr.max_return_amount IS NOT NULL
), DateRange AS (
    SELECT 
        d.d_date,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS year_month_rank
    FROM date_dim d
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
), ItemReturnSummary AS (
    SELECT 
        id.i_item_id,
        dr.d_year,
        SUM(CASE WHEN cr.cr_return_quantity IS NULL THEN 0 ELSE cr.cr_return_quantity END) AS total_returns
    FROM ItemDetails id
    LEFT JOIN catalog_returns cr ON id.i_item_id = cr.cr_item_sk
    JOIN DateRange dr ON cr.cr_returned_date_sk = dr.d_date
    GROUP BY id.i_item_id, dr.d_year
)
SELECT 
    rs.ws_item_sk,
    id.i_item_desc,
    id.return_reason,
    rs.total_sales,
    rs.order_count,
    irs.total_returns,
    CASE 
        WHEN rs.order_count = 0 THEN NULL 
        ELSE ROUND(rs.total_sales / rs.order_count, 2) 
    END AS avg_sales_per_order
FROM RecursiveSales rs
JOIN ItemDetails id ON rs.ws_item_sk = id.i_item_id
LEFT JOIN ItemReturnSummary irs ON id.i_item_id = irs.i_item_id
ORDER BY rs.sales_rank, id.i_item_desc
LIMIT 100
OFFSET 0;
