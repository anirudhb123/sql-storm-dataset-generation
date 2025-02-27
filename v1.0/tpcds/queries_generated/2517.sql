
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_sold_date_sk,
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_profit
    FROM 
        sales_summary ss
    WHERE 
        ss.profit_rank <= 10
),
customer_returns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(cr.cr_item_sk) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
)
SELECT 
    ca.ca_city,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ti.total_quantity) AS total_quantity_sold,
    COALESCE(SUM(cr.total_returns), 0) AS total_item_returns,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    top_items ti ON c.c_customer_sk = ti.ws_item_sk
LEFT JOIN 
    customer_returns cr ON c.c_customer_sk = cr.returning_customer_sk
WHERE 
    cd.cd_gender = 'F' AND
    cd.cd_marital_status = 'M' AND
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
ORDER BY 
    total_quantity_sold DESC;
