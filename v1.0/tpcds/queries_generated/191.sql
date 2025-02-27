
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
HighSpenders AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    WHERE cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
RecentReturns AS (
    SELECT 
        cr.cr_order_number,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE - INTERVAL '30 DAY')
    GROUP BY cr.cr_order_number
)
SELECT 
    h.c_customer_id,
    h.total_sales,
    h.cd_gender,
    h.cd_marital_status,
    r.total_returns,
    CASE 
        WHEN r.total_returns IS NULL THEN 'No Returns'
        WHEN r.total_returns > 0 THEN 'Returned'
        ELSE 'Completed'
    END AS return_status
FROM 
    HighSpenders h
LEFT JOIN RecentReturns r ON h.c_customer_id = r.cr_order_number
WHERE 
    h.rank <= 10
ORDER BY 
    h.total_sales DESC;
