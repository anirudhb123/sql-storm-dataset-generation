
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 50.00
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_return_quantity,
        SUM(cr.return_amt_inc_tax) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_country = 'USA'
    GROUP BY 
        ca.ca_state
)
SELECT 
    ss.ca_state,
    ss.total_customers,
    ss.total_sales_quantity,
    ss.total_sales_profit,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    RANK() OVER (ORDER BY ss.total_sales_profit DESC) AS state_rank
FROM 
    SalesSummary ss
LEFT JOIN 
    CustomerReturns cr ON ss.total_customers = cr.returning_customer_sk
WHERE 
    ss.total_sales_profit > 1000
ORDER BY 
    ss.total_sales_profit DESC;
