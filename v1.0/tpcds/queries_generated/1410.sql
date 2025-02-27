
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        DATEDIFF(DAY, MIN(d.d_date), MAX(d.d_date)) AS selling_duration_days
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws_item_sk
),
HighValueItems AS (
    SELECT 
        ss.ss_item_sk,
        ss.total_quantity_sold,
        ss.total_net_paid,
        ss.selling_duration_days,
        RANK() OVER (ORDER BY ss.total_net_paid DESC) AS revenue_rank
    FROM 
        SalesSummary ss
    WHERE 
        ss.total_net_paid > (SELECT AVG(total_net_paid) FROM SalesSummary)
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    hvi.total_quantity_sold,
    hvi.total_net_paid,
    COALESCE(cr.total_returns, 0) AS total_returns,
    CASE 
        WHEN hvi.total_quantity_sold > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS sales_category,
    hvi.selling_duration_days
FROM 
    HighValueItems hvi
JOIN 
    item i ON hvi.ss_item_sk = i.i_item_sk
LEFT JOIN 
    CustomerReturns cr ON hvi.ss_item_sk = cr.sr_item_sk
WHERE 
    hvi.revenue_rank <= 10
ORDER BY 
    hvi.total_net_paid DESC;
