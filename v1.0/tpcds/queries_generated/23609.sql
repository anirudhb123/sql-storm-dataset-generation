
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk, sr_returned_date_sk
),
AggCustomer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity,
        COUNT(sr.c_returning_customer_sk) AS return_count_below_avg
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', d.d_date) AS month,
        SUM(ws_net_profit) AS total_monthly_profit,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS monthly_order_count
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        month
),
SalesComparison AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_returns,
        m.total_monthly_profit,
        m.month,
        CASE
            WHEN s.total_return_quantity > m.total_monthly_profit THEN 'High Return'
            ELSE 'Normal Return'
        END AS return_status
    FROM 
        AggCustomer s
    JOIN 
        MonthlySales m ON EXTRACT(MONTH FROM m.month) = s.total_return_count
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_returns,
    rc.total_return_quantity,
    COALESCE(sc.month, 'No Sales') AS month,
    COALESCE(sc.return_status, 'No Status') AS return_status,
    RANK() OVER (ORDER BY rc.total_return_quantity DESC) AS return_rank
FROM 
    RankedReturns rc
LEFT JOIN 
    SalesComparison sc ON rc.sr_customer_sk = sc.c_customer_sk
WHERE 
    rc.rank_quantity <= 10
ORDER BY 
    rc.total_return_quantity DESC,
    return_rank ASC;
