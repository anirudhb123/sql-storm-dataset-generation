
WITH SalesSummary AS (
    SELECT 
        COALESCE(ws_bill_customer_sk, cs_bill_customer_sk, ss_customer_sk) AS customer_sk,
        COALESCE(ws_net_profit, cs_net_profit, ss_net_profit) AS total_profit,
        d_year,
        d_month_seq
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    JOIN 
        date_dim d ON COALESCE(ws_sold_date_sk, cs_sold_date_sk, ss_sold_date_sk) = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
)
SELECT 
    d_year, 
    d_month_seq, 
    SUM(total_profit) AS monthly_profit,
    COUNT(DISTINCT customer_sk) AS unique_customers,
    AVG(total_profit) OVER (PARTITION BY d_year ORDER BY d_month_seq) AS avg_profit_per_month,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(total_profit) DESC) AS profit_rank
FROM 
    SalesSummary
GROUP BY 
    d_year, d_month_seq
HAVING 
    SUM(total_profit) > (SELECT AVG(total_profit) FROM SalesSummary)
ORDER BY 
    d_year, d_month_seq;
