
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        c.c_first_name,
        c.c_last_name,
        0 AS depth
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        c.c_first_name,
        c.c_last_name,
        ch.depth + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        wr.wr_item_sk
),
Metrics AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rd.total_return_loss, 0) AS total_return_loss,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    m.ws_item_sk,
    m.total_quantity,
    m.total_net_profit,
    m.total_return_quantity,
    m.total_return_loss,
    CASE 
        WHEN m.total_net_profit > 1000 THEN 'High'
        WHEN m.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profitability_category
FROM 
    Metrics m
JOIN 
    CustomerHierarchy ch ON ch.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk = ch.c_current_cdemo_sk)
WHERE 
    m.profit_rank <= 10
ORDER BY 
    m.total_net_profit DESC, 
    ch.depth;
