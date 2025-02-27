
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
ReturnStats AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_qty,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ca.ca_city,
    CAST(COALESCE(rs.avg_net_paid, 0) AS DECIMAL(10,2)) AS average_sale,
    COALESCE(rt.total_returned_qty, 0) AS total_returns,
    CASE 
        WHEN COALESCE(rt.total_returns, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    RankedSales rs ON rs.web_site_sk = c.c_current_hdemo_sk
LEFT JOIN 
    ReturnStats rt ON rt.wr_item_sk = rs.web_site_sk
WHERE 
    ca.ca_state = 'CA' 
    AND EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_sold_date_sk = rs.ws_sold_date_sk 
        AND ss.ss_quantity > 0
    )
GROUP BY 
    ca.ca_city, rs.avg_net_paid, rt.total_returned_qty
HAVING 
    AVG(rs.avg_net_paid) > 100.00 
ORDER BY 
    unique_customers DESC;
