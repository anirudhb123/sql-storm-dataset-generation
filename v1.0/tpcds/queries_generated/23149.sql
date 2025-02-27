
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS rank_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
TotalReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        AVG(cr_return_amount) AS avg_return_amount,
        MAX(cr_return_tax) AS max_return_tax
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
DiscountedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS discount_orders
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_ext_discount_amt > 0
    GROUP BY 
        cs.cs_item_sk
),
TopReturningItems AS (
    SELECT 
        tr.cr_item_sk,
        tr.total_return_quantity,
        tr.avg_return_amount,
        tr.max_return_tax,
        ds.total_discount,
        ds.discount_orders
    FROM 
        TotalReturns tr
    LEFT JOIN 
        DiscountedSales ds ON tr.cr_item_sk = ds.cs_item_sk
    WHERE 
        tr.total_return_quantity > 5 OR ds.total_discount IS NOT NULL
),
FinalResults AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.ws_net_paid,
        tri.total_return_quantity,
        tri.avg_return_amount,
        tri.max_return_tax,
        tri.total_discount,
        tri.discount_orders
    FROM 
        RankedSales rs
    LEFT JOIN 
        TopReturningItems tri ON rs.ws_order_number = tri.cr_item_sk
    WHERE 
        rs.rank_paid <= 10
)
SELECT 
    fr.web_site_sk,
    fr.ws_order_number,
    COUNT(CASE WHEN fr.total_return_quantity IS NOT NULL THEN 1 END) AS return_count,
    SUM(COALESCE(fr.ws_net_paid, 0) - COALESCE(fr.total_discount, 0)) AS adjusted_net_paid,
    MAX(fr.avg_return_amount) AS max_return,
    STRING_AGG(CASE WHEN fr.total_return_quantity IS NOT NULL THEN CONCAT('Item: ', fr.ws_order_number, ' Quantity: ', fr.total_return_quantity) END, '; ') AS return_items_details
FROM 
    FinalResults fr
GROUP BY 
    fr.web_site_sk, fr.ws_order_number
HAVING 
    SUM(fr.ws_quantity) > 0 AND COUNT(fr.ws_order_number) > 1
ORDER BY 
    adjusted_net_paid DESC, return_count ASC
LIMIT 100;
