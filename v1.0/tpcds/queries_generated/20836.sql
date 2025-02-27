
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        c.c_last_name, 
        c.c_first_name, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_last_name, c.c_first_name
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        c.last_name,
        c.first_name,
        c.total_profit,
        RANK() OVER (ORDER BY c.total_profit DESC) AS rank
    FROM 
        CustomerSales c
)
SELECT 
    tc.customer_id,
    tc.last_name,
    tc.first_name,
    COALESCE(ss.total_sales, 0) AS store_sales_total,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    (CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) > 0 THEN 'Has Sales' 
        ELSE 'No Sales' 
    END) AS sales_status
FROM 
    TopCustomers tc
LEFT JOIN 
    (SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_sales
     FROM 
        store_returns 
     GROUP BY 
        sr_customer_sk) ss ON tc.customer_id = ss.sr_customer_sk
LEFT JOIN 
    catalog_returns cr ON tc.customer_id = cr.cr_returning_customer_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = tc.customer_id
WHERE 
    (tc.rank <= 10 OR 
    EXISTS (
        SELECT 1 FROM store s 
        WHERE s.s_store_id = 'S0001'
        AND s.s_closed_date_sk IS NULL
    ))
GROUP BY 
    tc.customer_id, 
    tc.last_name, 
    tc.first_name, 
    ss.total_sales
HAVING 
    COUNT(ws.ws_order_number) > 1 OR 
    SUM(cr.cr_return_amount) > 0
ORDER BY 
    total_profit DESC NULLS LAST;
