
WITH RECURSIVE MonthSales AS (
    SELECT 
        d.d_year, 
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year >= 2022 
    GROUP BY d.d_year, d.d_month_seq
    
    UNION ALL
    
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(cs_ext_sales_price)
    FROM date_dim d
    JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE d.d_year >= 2022 
    GROUP BY d.d_year, d.d_month_seq
),
SalesRanked AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        total_sales,
        RANK() OVER (PARTITION BY d.d_year ORDER BY total_sales DESC) AS sales_rank
    FROM MonthSales
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        count(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS customer_rank
    FROM CustomerSummary cs
)
SELECT 
    s.d_year,
    s.d_month_seq,
    s.total_sales,
    tc.total_orders,
    tc.total_profit
FROM SalesRanked s
LEFT JOIN TopCustomers tc ON tc.total_orders > 5
WHERE s.sales_rank <= 10
AND s.total_sales IS NOT NULL
ORDER BY s.d_year, s.d_month_seq, tc.total_profit DESC;
