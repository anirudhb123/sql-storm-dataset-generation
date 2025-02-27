
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) as sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        COALESCE(NULLIF(i.i_size, ''), 'N/A') AS size,
        COALESCE(NULLIF(i.i_color, ''), 'Color Unknown') AS color
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE
        AND (i.i_rec_end_date >= CURRENT_DATE OR i.i_rec_end_date IS NULL)
),
StoreReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalMetrics AS (
    SELECT 
        id.i_item_id, 
        id.i_product_name,
        RS.total_sold,
        SR.total_returns,
        SR.total_returned_amount,
        COALESCE(RS.total_sold, 0) - COALESCE(SR.total_returns, 0) AS net_sales,
        CASE 
            WHEN RS.sales_rank = 1 THEN 'Best Seller'
            ELSE 'Regular'
        END AS sales_category,
        CASE 
            WHEN SR.total_returned_amount > 1000 THEN 'High Return'
            WHEN SR.total_returned_amount BETWEEN 100 AND 1000 THEN 'Moderate Return'
            ELSE 'Low Return'
        END AS return_category
    FROM 
        ItemDetails id
    LEFT JOIN 
        RankedSales RS ON id.i_item_sk = RS.ws_item_sk
    LEFT JOIN 
        StoreReturns SR ON id.i_item_sk = SR.sr_item_sk
)
SELECT 
    *,
    CASE 
        WHEN net_sales < 0 THEN 'Oversold'
        ELSE 'In Demand'
    END AS demand_status
FROM 
    FinalMetrics
WHERE 
    total_sold IS NOT NULL
    AND (total_returned_quantity IS NULL OR total_returned_quantity < 5)
ORDER BY 
    net_sales DESC 
FETCH FIRST 10 ROWS ONLY;
