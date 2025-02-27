
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_revenue,
        AVG(ss.ss_net_profit) AS avg_profit
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.total_revenue,
        cs.avg_profit,
        RANK() OVER (ORDER BY cs.total_revenue DESC) AS revenue_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        tc.customer_id,
        tc.total_sales,
        tc.total_revenue,
        CASE 
            WHEN tc.avg_profit > 100 THEN 'High'
            WHEN tc.avg_profit BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM TopCustomers tc
    WHERE revenue_rank <= 10
),
RecentReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS returns_count
    FROM web_returns
    WHERE wr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY wr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        hv.customer_id,
        hv.total_sales,
        hv.total_revenue,
        hv.profit_category,
        COALESCE(rr.returns_count, 0) AS returns_count
    FROM HighValueCustomers hv
    LEFT JOIN RecentReturns rr ON hv.customer_id = rr.wr_returning_customer_sk
)
SELECT 
    fr.customer_id,
    fr.total_sales,
    fr.total_revenue,
    fr.profit_category,
    fr.returns_count,
    CASE 
        WHEN fr.returns_count > 5 THEN 'High Return'
        WHEN fr.returns_count BETWEEN 1 AND 5 THEN 'Normal Return'
        ELSE 'No Returns'
    END AS return_status
FROM FinalReport fr
WHERE fr.total_revenue > 1000
ORDER BY fr.total_revenue DESC;
