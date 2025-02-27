
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ws.ws_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
CustomerSummary AS (
    SELECT 
        rs.c_customer_id,
        rs.c_first_name,
        rs.c_last_name,
        rs.total_net_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.c_customer_id = cr.returning_customer_sk
    WHERE 
        rs.rank_profit <= 5
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_net_profit,
    cs.total_returns,
    cs.total_return_amount,
    CASE 
        WHEN cs.total_net_profit > 1000 THEN 'High Value'
        WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    CustomerSummary cs
ORDER BY 
    cs.total_net_profit DESC;
