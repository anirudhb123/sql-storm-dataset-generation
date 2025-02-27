
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        DENSE_RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS dense_rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND 
                                   (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
CustomerReturns AS (
    SELECT 
        wr_refunded_customer_sk, 
        SUM(wr_net_loss) AS total_return_loss
    FROM 
        web_returns
    GROUP BY 
        wr_refunded_customer_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales_profit,
        COALESCE(cr.total_return_loss, 0) AS total_return_loss
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_sales_profit,
    ss.total_return_loss,
    CASE 
        WHEN ss.total_sales_profit - ss.total_return_loss < 0 THEN 'Net Loss'
        ELSE 'Net Profit'
    END AS profit_status,
    (SELECT COUNT(*) FROM RankedSales rs WHERE rs.ws_order_number = ss.c_customer_sk) AS rank_count
FROM 
    SalesSummary ss
WHERE 
    ss.total_sales_profit > 1000
ORDER BY 
    ss.total_sales_profit DESC,
    profit_status ASC;
