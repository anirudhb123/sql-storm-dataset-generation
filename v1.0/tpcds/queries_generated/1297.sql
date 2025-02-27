
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ship_customer_sk,
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M' AND 
        ws.sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.bill_customer_sk, ws.ship_customer_sk, ws.web_site_sk
),
TopCustomers AS (
    SELECT 
        bill_customer_sk,
        ship_customer_sk,
        web_site_sk,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)
SELECT 
    tc.bill_customer_sk,
    tc.ship_customer_sk,
    tc.web_site_sk,
    tc.total_net_profit,
    COALESCE(COUNT(sr.ticket_number), 0) AS total_returns,
    COALESCE(AVG(sr.return_amt), 0) AS avg_return_amount
FROM 
    TopCustomers tc
LEFT JOIN 
    store_returns sr ON tc.bill_customer_sk = sr.sr_customer_sk
GROUP BY 
    tc.bill_customer_sk, tc.ship_customer_sk, tc.web_site_sk, tc.total_net_profit
HAVING 
    SUM(tc.total_net_profit) > 1000
ORDER BY 
    tc.total_net_profit DESC;
