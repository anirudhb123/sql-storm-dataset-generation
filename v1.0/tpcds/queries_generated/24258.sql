
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) as sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND c.c_birth_year % 2 = 0
),
ReturnDetails AS (
    SELECT
        sr.store_sk,
        SUM(sr.sr_return_quantity) AS total_returned_quantity,
        AVG(sr.sr_return_amt) AS avg_return_amount
    FROM 
        store_returns sr
    LEFT JOIN 
        store s ON sr.s_store_sk = s.s_store_sk
    GROUP BY 
        sr.store_sk
)
SELECT 
    r.store_sk,
    r.total_returned_quantity,
    r.avg_return_amount,
    COALESCE(SUM(rs.ws_quantity), 0) AS total_sales_quantity,
    COUNT(DISTINCT rs.ws_order_number) as total_sales_orders,
    CASE 
        WHEN r.avg_return_amount IS NULL THEN 'No Returns'
        ELSE 'Returns Available' 
    END AS return_status,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', CAST(rs.ws_order_number AS CHAR(16)), CAST(rs.ws_sales_price AS DECIMAL(10,2))), '; ') AS order_info
FROM 
    ReturnDetails r
LEFT JOIN 
    RankedSales rs ON r.store_sk = rs.web_site_sk
WHERE 
    r.total_returned_quantity > 0
    OR (SELECT COUNT(*) FROM store s2 WHERE s2.s_closed_date_sk IS NOT NULL AND s2.s_store_sk = r.store_sk) > 0
GROUP BY 
    r.store_sk, r.total_returned_quantity, r.avg_return_amount
HAVING 
    SUM(rs.ws_quantity) < 10000
ORDER BY 
    r.total_returned_quantity DESC, r.avg_return_amount ASC
LIMIT 50;
