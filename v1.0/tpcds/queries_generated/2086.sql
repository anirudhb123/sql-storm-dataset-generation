
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank_per_order
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cr_returning_customer_sk
),
SalesByState AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ca.ca_state
)
SELECT 
    sbs.ca_state,
    sbs.total_net_profit,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    rs.ws_order_number,
    rs.ws_item_sk,
    rs.ws_sales_price,
    rs.ws_net_profit
FROM 
    SalesByState sbs
LEFT JOIN 
    CustomerReturns cr ON cr.cr_returning_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk LIMIT 1)  -- Correlated subquery
LEFT JOIN 
    RankedSales rs ON rs.ws_order_number = (SELECT ws_order_number FROM web_sales WHERE ws_item_sk = rs.ws_item_sk LIMIT 1)  -- Subquery
WHERE 
    sbs.total_net_profit > (SELECT AVG(total_net_profit) FROM SalesByState) -- Predicate using aggregate
ORDER BY 
    sbs.total_net_profit DESC, 
    rs.ws_net_profit DESC;
