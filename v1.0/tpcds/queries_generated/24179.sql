
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2)
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        SUM(CASE WHEN ws.ws_quantity > 10 THEN ws.ws_net_profit ELSE 0 END) AS high_volume_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_email_address, cd.cd_gender, cd.cd_marital_status
),
SalesReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
FinalSales AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_email_address,
        cd.gender,
        cd.marital_status,
        COALESCE(sr.total_returns, 0) AS total_returns,
        COALESCE(sr.return_count, 0) AS return_count,
        SUM(rs.ws_net_profit) AS total_profit,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesReturns sr ON cd.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        RankedSales rs ON cd.c_customer_sk = rs.web_site_sk
    GROUP BY 
        cd.c_customer_sk, cd.c_email_address, cd.gender, cd.marital_status, sr.total_returns, sr.return_count
)
SELECT 
    f.c_customer_sk,
    f.c_email_address,
    f.gender,
    f.marital_status,
    CASE WHEN f.total_profit > 1000 THEN 'VIP' ELSE 'Regular' END AS customer_status,
    f.total_returns,
    f.return_count,
    f.total_profit,
    RANK() OVER (ORDER BY f.total_profit DESC) AS profit_rank
FROM 
    FinalSales f
WHERE 
    f.total_profit IS NOT NULL
    AND CAST(f.c_email_address AS CHAR(50)) LIKE '%@%'
ORDER BY 
    profit_rank
FETCH FIRST 100 ROWS ONLY;
