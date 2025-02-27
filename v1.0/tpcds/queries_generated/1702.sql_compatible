
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        ws.web_site_sk
), 
high_profit_websites AS (
    SELECT 
        web_site_sk, 
        total_orders, 
        total_profit
    FROM 
        ranked_sales 
    WHERE 
        rank_profit <= 5
), 
sales_returns AS (
    SELECT 
        wr.web_page_sk,
        SUM(wr.return_amt) AS total_return_amt,
        COUNT(DISTINCT wr.returning_customer_sk) AS total_returning_customers
    FROM 
        web_returns wr
    JOIN 
        web_site ws ON wr.web_page_sk = ws.web_site_sk
    GROUP BY 
        wr.web_page_sk
)
SELECT 
    hs.web_site_sk,
    hs.total_orders,
    hs.total_profit,
    COALESCE(sr.total_return_amt, 0) AS total_return_amt,
    COALESCE(sr.total_returning_customers, 0) AS total_returning_customers
FROM 
    high_profit_websites hs
LEFT JOIN 
    sales_returns sr ON hs.web_site_sk = sr.web_page_sk
WHERE 
    hs.total_profit > 10000
ORDER BY 
    hs.total_profit DESC;
