
WITH RECURSIVE SalesGrowth AS (
    SELECT 
        d_year, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d_year
    UNION ALL
    SELECT 
        d_year, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        date_dim d
    JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        d_year
),
RankedSales AS (
    SELECT 
        d_month_seq, 
        SUM(ws_net_profit) AS monthly_profit,
        RANK() OVER (PARTITION BY d_month_seq ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d_month_seq
),
HighProfitCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > (SELECT AVG(ws_net_profit) FROM web_sales)
),
SalesReturns AS (
    SELECT 
        sr.returned_date_sk,
        SUM(sr.return_amt) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk
)
SELECT 
    d.d_year,
    SUM(ws.ws_net_profit) AS total_sales,
    COALESCE(sr.total_returns, 0) AS total_returns,
    (SUM(ws.ws_net_profit) - COALESCE(sr.total_returns, 0)) AS net_sales,
    ARRAY_AGG(DISTINCT hc.c_customer_id) AS high_profit_customers
FROM 
    date_dim d
LEFT JOIN 
    web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN 
    SalesReturns sr ON d.d_date_sk = sr.returned_date_sk
LEFT JOIN 
    HighProfitCustomers hc ON hc.total_spent > (SELECT AVG(total_spent) FROM HighProfitCustomers)
WHERE 
    d.d_year BETWEEN 2020 AND 2022
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;
