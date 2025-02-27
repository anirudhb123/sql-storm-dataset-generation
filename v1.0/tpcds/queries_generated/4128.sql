
WITH CustomerReturns AS (
    SELECT 
        COALESCE(sr_customer_sk, wr_returned_customer_sk) AS customer_sk,
        COALESCE(SUM(sr_return_quantity), SUM(wr_return_quantity)) AS total_returns,
        COALESCE(SUM(sr_return_amt_inc_tax), SUM(wr_return_amt_inc_tax)) AS total_return_amount
    FROM 
        store_returns AS sr
    FULL OUTER JOIN 
        web_returns AS wr ON sr_ticket_number = wr_order_number AND sr_item_sk = wr_item_sk
    GROUP BY 
        COALESCE(sr_customer_sk, wr_returned_customer_sk)
),
RevenueStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeBandStats AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(rs.total_profit) AS avg_profit
    FROM 
        household_demographics AS hd
    LEFT JOIN 
        RevenueStats AS rs ON hd.hd_demo_sk = rs.c_customer_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(cbs.customer_count, 0) AS customer_count,
    COALESCE(cbs.avg_profit, 0.00) AS avg_profit,
    CASE 
        WHEN COALESCE(cbs.avg_profit, 0) > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM 
    income_band AS ib
LEFT JOIN 
    IncomeBandStats AS cbs ON ib.ib_income_band_sk = cbs.hd_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
