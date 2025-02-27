
WITH customer_returns AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        AVG(sr_return_amt_inc_tax) AS avg_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        sr_store_sk
),
web_sales_data AS (
    SELECT 
        ws_store_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_store_sk
),
aggregate_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_sales_profit,
        COALESCE(cr.total_returns, 0) AS total_store_returns,
        COALESCE(cr.total_returned_quantity, 0) AS total_quantity_returned,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY SUM(COALESCE(ws.ws_net_profit, 0)) DESC) AS city_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_returns cr ON cr.sr_store_sk = ws.ws_store_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city
    HAVING 
        SUM(COALESCE(ws.ws_net_profit, 0)) > 1000 
        OR COALESCE(cr.total_returns, 0) > 0
),
final_report AS (
    SELECT 
        ad.c_first_name,
        ad.c_last_name,
        ad.ca_city,
        ad.total_web_sales_profit,
        ad.total_store_returns,
        ad.total_quantity_returned,
        CASE 
            WHEN ad.total_web_sales_profit IS NULL THEN 'No Sales'
            WHEN ad.total_web_sales_profit > 1000 THEN 'High Sales'
            ELSE 'Low Sales'
        END AS sales_status
    FROM 
        aggregate_data ad
)
SELECT 
    fr.*,
    DENSE_RANK() OVER (ORDER BY fr.total_web_sales_profit DESC) AS sales_rank
FROM 
    final_report fr
WHERE 
    EXISTS (SELECT 1 FROM date_dim dd WHERE dd.d_year = EXTRACT(YEAR FROM CURRENT_DATE) AND dd.d_month_seq <= 6)
ORDER BY 
    sales_rank;
