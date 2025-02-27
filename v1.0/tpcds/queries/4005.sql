
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
high_profit_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ws_sold_date_sk ORDER BY ss.total_profit DESC) AS rn
    FROM 
        sales_summary AS ss
    WHERE 
        ss.total_profit > (SELECT AVG(total_profit) FROM sales_summary)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
returns_summary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    hpi.ws_item_sk,
    hpi.total_profit,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned_amount, 0.00) AS total_returned_amount,
    CASE 
        WHEN COALESCE(rs.total_returns, 0) = 0 THEN 'No Returns'
        ELSE 'Returned'
    END AS return_status
FROM 
    high_profit_items AS hpi
JOIN 
    customer_info AS ci ON ci.c_customer_sk IN (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = hpi.ws_item_sk
    )
LEFT JOIN 
    returns_summary AS rs ON hpi.ws_item_sk = rs.sr_item_sk
WHERE 
    hpi.rn = 1
ORDER BY 
    hpi.total_profit DESC, ci.c_last_name ASC;
