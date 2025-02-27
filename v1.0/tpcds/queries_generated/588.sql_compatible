
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        DATEADD(DAY, d.d_dom, d.d_date) AS sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        cr.cr_item_sk
),
HighValueItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COUNT(rr.ws_order_number) AS total_orders,
        AVG(rr.ws_sales_price) AS avg_price
    FROM 
        item i
    LEFT JOIN 
        RankedSales rr ON i.i_item_sk = rr.ws_item_sk AND rr.rank_price = 1
    GROUP BY 
        i.i_item_sk, i.i_item_desc
    HAVING 
        COUNT(rr.ws_order_number) > 5 AND AVG(rr.ws_sales_price) > 200
)
SELECT 
    hvi.i_item_sk,
    hvi.i_item_desc,
    COALESCE(tr.total_returned, 0) AS total_returns,
    hvi.total_orders,
    hvi.avg_price,
    CASE 
        WHEN COALESCE(tr.total_returned, 0) > (0.1 * hvi.total_orders) THEN 'High Return'
        ELSE 'Normal Return'
    END AS return_status
FROM
    HighValueItems hvi
LEFT OUTER JOIN 
    TotalReturns tr ON hvi.i_item_sk = tr.cr_item_sk
ORDER BY 
    hvi.avg_price DESC, total_returns ASC;
