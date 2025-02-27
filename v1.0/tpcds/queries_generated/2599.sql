
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk
),
SalesData AS (
    SELECT 
        ws.sold_date_sk,
        SUM(ws.net_profit) AS total_sales_profit,
        COUNT(DISTINCT ws.order_number) AS order_count,
        SUM(ws.quantity) AS total_units_sold
    FROM 
        web_sales ws
    GROUP BY 
        ws.sold_date_sk
),
TotalReturnsAndSales AS (
    SELECT 
        d.d_date_sk AS date_key,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_return_amount, 0) AS total_return_amount,
        COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
        COALESCE(s.order_count, 0) AS order_count,
        COALESCE(s.total_units_sold, 0) AS total_units_sold
    FROM 
        date_dim d
    LEFT JOIN 
        CustomerReturns c ON d.d_date_sk = c.returned_date_sk
    LEFT JOIN 
        SalesData s ON d.d_date_sk = s.sold_date_sk
)
SELECT 
    date_key,
    total_returns,
    total_return_amount,
    total_sales_profit,
    order_count,
    total_units_sold,
    total_sales_profit - total_return_amount AS net_profit_after_returns,
    CASE 
        WHEN total_units_sold > 0 THEN total_sales_profit / total_units_sold
        ELSE NULL
    END AS avg_sales_per_unit,
    (CASE 
        WHEN total_returns > 0 THEN (total_returns::decimal / NULLIF(order_count, 0)) * 100
        ELSE 0
    END) AS return_rate_percentage
FROM 
    TotalReturnsAndSales
WHERE 
    (total_sales_profit > 1000 OR total_returns > 5)
ORDER BY 
    date_key DESC
LIMIT 100;
