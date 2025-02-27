
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
HighValueReturns AS (
    SELECT 
        r.*, 
        i.i_item_desc,
        i.i_current_price
    FROM 
        RankedReturns r
    JOIN 
        item i ON r.sr_item_sk = i.i_item_sk
    WHERE 
        r.return_rank = 1
), 
DateRange AS (
    SELECT 
        MIN(d_date) AS start_date,
        MAX(d_date) AS end_date
    FROM 
        date_dim
    WHERE 
        d_year = 2023
), 
SalesSummary AS (
    SELECT 
        i.i_item_id,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_qty) AS quantity_sold
    FROM 
        web_sales
    JOIN 
        item i ON ws_item_sk = i.i_item_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_date = (SELECT start_date FROM DateRange)) AND 
                                   (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = (SELECT end_date FROM DateRange))
    GROUP BY 
        i.i_item_id
)
SELECT 
    hvr.i_item_desc,
    hvr.total_return_quantity,
    hvr.total_return_amt,
    ss.total_sales,
    ss.order_count,
    ss.quantity_sold,
    CASE 
        WHEN COALESCE(ss.total_sales, 0) = 0 THEN 'No Sales' 
        ELSE 'Sales Available' 
    END AS sales_status
FROM 
    HighValueReturns hvr
LEFT JOIN 
    SalesSummary ss ON hvr.i_item_id = ss.i_item_id
ORDER BY 
    hvr.total_return_amt DESC, 
    hvr.total_return_quantity DESC;
