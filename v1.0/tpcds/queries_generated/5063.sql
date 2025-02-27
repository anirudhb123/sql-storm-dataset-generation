
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        MAX(ws.ws_net_paid_inc_tax) AS max_net_paid,
        MIN(ws.ws_net_paid) AS min_net_paid
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
), StoreReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
), GrossPerformance AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        sr.total_returns,
        sr.total_return_amount,
        (cs.total_sales - COALESCE(sr.total_return_amount, 0)) AS net_sales
    FROM 
        CustomerSales cs
    LEFT JOIN 
        StoreReturns sr ON cs.c_customer_id = sr.sr_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    GrossPerformance
WHERE 
    order_count > 5
ORDER BY 
    net_sales DESC, total_sales DESC
LIMIT 50;
