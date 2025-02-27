
WITH total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_profit_items AS (
    SELECT 
        ts.ws_item_sk, 
        ts.total_profit, 
        i.i_item_desc,
        COUNT(DISTINCT ws_order_number) OVER (PARTITION BY ts.ws_item_sk) AS order_count,
        RANK() OVER (ORDER BY ts.total_profit DESC) AS item_rank
    FROM 
        total_sales ts
    JOIN 
        item i ON ts.ws_item_sk = i.i_item_sk
    WHERE 
        ts.rank <= 10
),
customer_returns AS (
    SELECT 
        wr_returning_customer_sk, 
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
returning_customers AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_return_amt, 0) AS total_return,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_returns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    hi.ws_item_sk,
    hi.total_profit,
    hi.i_item_desc,
    rc.c_customer_sk,
    rc.total_return,
    rc.cd_gender,
    rc.cd_marital_status
FROM 
    high_profit_items hi
JOIN 
    returning_customers rc ON hi.ws_item_sk = rc.c_customer_sk 
WHERE 
    (rc.total_return > 1000 OR rc.cd_marital_status = 'M')
ORDER BY 
    hi.total_profit DESC, 
    rc.total_return DESC;
