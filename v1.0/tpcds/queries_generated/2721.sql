
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_item_sk) AS unique_items_returned
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amt,
        cr.unique_items_returned,
        DENSE_RANK() OVER (ORDER BY cr.total_return_amt DESC) AS rank
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_returns > 0
),
DateRange AS (
    SELECT 
        d.d_date,
        d.d_month_seq,
        d.d_year 
    FROM date_dim d 
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
SalesSummary AS (
    SELECT 
        DATE(d.d_date) AS sale_date,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_amount
    FROM web_sales ws
    JOIN DateRange d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY sale_date
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    ss.sale_date,
    ss.total_sales,
    ss.total_sales_amount,
    CASE 
        WHEN ss.total_sales_amount > (SELECT AVG(total_sales_amount) FROM SalesSummary) 
        THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS sales_performance,
    COUNT(DISTINCT ws.ws_item_sk) AS items_bought
FROM TopCustomers tc
LEFT JOIN SalesSummary ss ON ss.sale_date = (SELECT MAX(sale_date) FROM SalesSummary)
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = tc.c_customer_id
GROUP BY 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    ss.sale_date,
    ss.total_sales,
    ss.total_sales_amount
ORDER BY tc.total_return_amt DESC, ss.total_sales_amount DESC
FETCH FIRST 10 ROWS ONLY;
