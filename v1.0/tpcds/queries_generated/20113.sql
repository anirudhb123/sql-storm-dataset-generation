
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        cr.wr_returning_customer_sk,
        SUM(cr.wr_return_quantity) AS total_returned,
        COUNT(cr.wr_order_number) AS return_count
    FROM 
        web_returns cr
    GROUP BY 
        cr.wr_returning_customer_sk
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        COALESCE(CAST(SUBSTRING(c.c_email_address, CHARINDEX('@', c.c_email_address) + 1, LEN(c.c_email_address)) AS VARCHAR(100)), 'Unknown') AS domain
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 500
        AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
)
SELECT 
    fc.c_customer_id,
    fr.total_returned,
    fr.return_count,
    AVG(rs.ws_sales_price) AS avg_sales_price,
    SUM(rs.ws_quantity) AS total_quantity,
    COUNT(DISTINCT rs.ws_order_number) AS unique_orders
FROM 
    FilteredCustomers fc
LEFT JOIN 
    CustomerReturns fr ON fc.c_customer_id = fr.wr_returning_customer_sk
LEFT JOIN 
    RankedSales rs ON fc.c_customer_id = CAST(rs.ws_order_number AS VARCHAR(16))
WHERE 
    fr.total_returned IS NULL OR fr.total_returned <= 10
GROUP BY 
    fc.c_customer_id, fr.total_returned, fr.return_count
HAVING 
    SUM(rs.ws_quantity) > 50 AND (COUNT(rs.ws_order_number) >= 5 OR AVG(rs.ws_sales_price) < 100)
ORDER BY 
    avg_sales_price DESC, total_quantity DESC
FETCH FIRST 100 ROWS ONLY;
