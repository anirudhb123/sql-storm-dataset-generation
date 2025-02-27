
WITH RECURSIVE sales_with_return AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_item_sk,
        ws_net_paid,
        ws_ext_sales_price,
        COALESCE(returns.total_return, 0) AS total_returns,
        ws_net_paid - COALESCE(returns.total_return, 0) AS net_profit
    FROM 
        web_sales ws
    LEFT JOIN (
        SELECT 
            wr.web_page_sk,
            wr_order_number,
            SUM(wr_return_amt_inc_tax) AS total_return
        FROM 
            web_returns wr
        GROUP BY 
            wr.web_page_sk, wr_order_number
    ) returns ON ws.ws_web_page_sk = returns.web_page_sk AND ws.ws_order_number = returns.wr_order_number
    WHERE 
        ws_sold_date_sk = (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023)
  
    UNION ALL
  
    SELECT 
        s.web_site_sk,
        s.ss_order_number,
        s.ss_item_sk,
        s.net_paid,
        s.ext_sales_price,
        COALESCE(returns.total_return, 0) AS total_returns,
        s.net_paid - COALESCE(returns.total_return, 0) AS net_profit
    FROM 
        store_sales s
    LEFT JOIN (
        SELECT 
            sr_store_sk,
            sr_order_number,
            SUM(sr_return_amt_inc_tax) AS total_return
        FROM 
            store_returns 
        GROUP BY 
            sr_store_sk, sr_order_number
    ) returns ON s.ss_store_sk = returns.sr_store_sk AND s.ss_order_number = returns.sr_order_number
    WHERE 
        ss_sold_date_sk = (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023)
)

SELECT 
    a.ca_country,
    COUNT(DISTINCT s.web_site_sk) AS num_websites,
    MAX(s.net_profit) AS highest_profit,
    AVG(s.net_profit) AS average_profit,
    SUM(s.net_profit) FILTER (WHERE s.total_returns = 0) AS total_sales_without_returns
FROM 
    sales_with_return s
JOIN 
    customer_address a ON a.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = s.ws_bill_customer_sk LIMIT 1)
GROUP BY 
    a.ca_country
ORDER BY 
    average_profit DESC
LIMIT 10;
