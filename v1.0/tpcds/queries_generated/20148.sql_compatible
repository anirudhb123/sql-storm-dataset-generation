
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT DISTINCT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_moy IN (SELECT DISTINCT d_moy FROM date_dim WHERE d_holiday = 'Y')
        )
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_month IN (SELECT DISTINCT d_moy FROM date_dim WHERE d_holiday = 'Y')
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.ws_net_paid) > (
            SELECT AVG(total_spent) 
            FROM (
                SELECT SUM(ws2.ws_net_paid) AS total_spent
                FROM web_sales ws2
                GROUP BY ws2.ws_bill_customer_sk
            ) AS spend
        )
),
RecentReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (
            SELECT MAX(d_date_sk)
            FROM date_dim
            WHERE d_year = 2023 AND d_current_day = 'Y'
        )
    GROUP BY 
        sr_item_sk
)
SELECT 
    cm.c_customer_id, 
    SUM(COALESCE(sales.ws_net_profit, 0)) AS total_profit,
    COUNT(DISTINCT sales.ws_order_number) AS total_orders,
    COALESCE(returns.return_count, 0) AS total_returns,
    COALESCE(returns.total_return_amt, 0) AS total_return_amt,
    RANK() OVER (ORDER BY SUM(COALESCE(sales.ws_net_profit, 0)) DESC) AS profit_rank
FROM 
    customer cm
LEFT JOIN 
    web_sales sales ON cm.c_customer_sk = sales.ws_bill_customer_sk
LEFT JOIN 
    RecentReturns returns ON sales.ws_item_sk = returns.sr_item_sk
WHERE 
    cm.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M')
    AND cm.c_current_addr_sk IS NOT NULL
GROUP BY 
    cm.c_customer_id
ORDER BY 
    total_profit DESC;
