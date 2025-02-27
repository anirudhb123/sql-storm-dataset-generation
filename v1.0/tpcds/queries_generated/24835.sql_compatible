
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_quantity DESC) AS rank_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL 
        AND ws.ws_quantity > 0
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned,
        COUNT(DISTINCT cr.order_number) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
    HAVING 
        SUM(cr.return_quantity) > 10
),
ItemReturnDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(arr.total_returned, 0) AS total_returned
    FROM 
        item i
    LEFT JOIN 
        CustomerReturns arr ON i.i_item_sk = arr.returning_customer_sk
)
SELECT 
    w.w_warehouse_name,
    addr.ca_city,
    CASE 
        WHEN (ir.total_returned IS NOT NULL AND ir.total_returned > 0) THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    SUM(rs.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT rs.ws_sold_date_sk) AS sales_days
FROM 
    RankedSales rs
JOIN 
    warehouse w ON rs.web_site_sk = w.w_warehouse_sk
JOIN 
    customer_address addr ON w.w_warehouse_sk = addr.ca_address_sk
LEFT JOIN 
    ItemReturnDetails ir ON rs.ws_item_sk = ir.i_item_sk
WHERE 
    (rs.rank_price <= 5 OR rs.rank_quantity <= 5) 
    AND w.w_warehouse_sq_ft > (SELECT AVG(w2.w_warehouse_sq_ft) FROM warehouse w2)
GROUP BY 
    w.warehouse_name, addr.ca_city, ir.total_returned
HAVING 
    SUM(rs.ws_net_profit) > 1000
ORDER BY 
    total_net_profit DESC, return_status;
