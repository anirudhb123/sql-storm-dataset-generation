
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER(PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 1 LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 3 ORDER BY d_date_sk DESC LIMIT 1)
),
AggregateReturns AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_web_page_sk
)
SELECT 
    ca.ca_country,
    SUM(CASE WHEN rs.profit_rank <= 10 THEN rs.ws_net_profit ELSE 0 END) AS top_profit_web_sales,
    COALESCE(SUM(ar.total_return_quantity), 0) AS total_returns,
    AVG(CASE WHEN ca.ca_state IS NOT NULL THEN ws.ws_net_profit END) AS avg_profit_in_states
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN 
    AggregateReturns ar ON rs.ws_item_sk = ar.wr_web_page_sk
LEFT JOIN 
    web_sales ws ON rs.ws_order_number = ws.ws_order_number
WHERE 
    ca.ca_country = 'USA'
    AND (c.c_first_shipto_date_sk IS NULL OR c.c_first_sales_date_sk IS NULL)
GROUP BY 
    ca.ca_country, ca.ca_state
HAVING 
    SUM(rs.ws_quantity) > 100
ORDER BY 
    total_returns DESC, avg_profit_in_states ASC;
