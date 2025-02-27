
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) as sale_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_returns,
        SUM(wr.return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
ItemSales AS (
    SELECT 
        i_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        i_item_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(fs.total_sold) AS total_items_sold,
    SUM(fs.total_revenue) AS total_revenue_generated,
    COALESCE(SUM(cr.total_returns), 0) AS total_returned_items,
    (SUM(fs.total_revenue) - COALESCE(SUM(cr.total_return_amt), 0)) AS net_revenue
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
LEFT JOIN 
    ItemSales fs ON fs.i_item_sk IN (
        SELECT ws.ws_item_sk 
        FROM web_sales ws
        WHERE ws.ws_order_number IN (SELECT ws_order_number FROM RankedSales WHERE sale_rank <= 10)
    )
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
ORDER BY 
    net_revenue DESC
LIMIT 10;
