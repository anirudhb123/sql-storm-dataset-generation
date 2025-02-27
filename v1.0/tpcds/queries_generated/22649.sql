
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        WS.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
        AND i.i_current_price > 0
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    SUM(COALESCE(rs.ws_sales_price, 0)) AS total_sales,
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    AVG(CASE WHEN rs.profit_rank = 1 THEN rs.ws_net_profit ELSE NULL END) AS avg_best_profit,
    CASE 
        WHEN cd.return_count > 0 THEN 'Has Returns'
        WHEN cd.cd_marital_status IS NULL THEN 'Unknown Status'
        ELSE 'No Returns'
    END AS return_status
FROM 
    customer_details cd
LEFT JOIN 
    ranked_sales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
GROUP BY 
    cd.c_customer_sk, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_purchase_estimate
HAVING 
    SUM(COALESCE(rs.ws_sales_price, 0)) > 1000
ORDER BY 
    total_sales DESC
LIMIT 10 OFFSET 5;
