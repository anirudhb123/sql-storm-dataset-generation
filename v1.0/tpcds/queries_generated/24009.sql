
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 6 AND 8
    GROUP BY 
        ws.web_site_sk
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IN (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = 2023 
                AND d.d_dom > 15
        )
    GROUP BY 
        wr.returning_customer_sk
)
SELECT 
    ca.ca_city,
    SUM(rs.total_quantity) AS total_sales_quantity,
    COALESCE(SUM(cr.total_returned_quantity), 0) AS total_returned_quantity,
    (SUM(rs.total_net_paid) - COALESCE(SUM(cr.total_returned_quantity), 0)) AS net_profit
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.web_site_sk
LEFT JOIN 
    CustomerReturns cr ON cr.returning_customer_sk = c.c_customer_sk 
WHERE 
    ca.ca_country = 'USA' 
    AND (c.c_birth_year IS NULL OR c.c_birth_year < 1990) 
GROUP BY 
    ca.ca_city
HAVING 
    net_profit > 10000 
ORDER BY 
    total_sales_quantity DESC, 
    total_returned_quantity ASC;
