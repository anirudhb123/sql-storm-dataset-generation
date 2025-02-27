
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
),
ReturnStats AS (
    SELECT 
        CR.cr_returning_customer_sk AS customer_sk,
        SUM(CASE WHEN CR.cr_reason_sk IS NOT NULL THEN CR.cr_return_amount ELSE 0 END) AS total_return_amt
    FROM 
        catalog_returns CR
    GROUP BY 
        CR.cr_returning_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    COALESCE(cs.web_orders_count, 0) AS web_orders_count,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0) - COALESCE(rs.total_return_amt, 0)) AS net_sales
FROM 
    CustomerSales cs
LEFT JOIN 
    StoreSales ss ON ss.ss_store_sk = (SELECT s_store_sk FROM store WHERE s_store_sk = cs.c_customer_sk)
LEFT JOIN 
    ReturnStats rs ON cs.c_customer_sk = rs.customer_sk
WHERE 
    (COALESCE(cs.total_web_sales, 0) > 500 OR COALESCE(ss.total_store_sales, 0) > 500)
ORDER BY 
    net_sales DESC
FETCH FIRST 100 ROWS ONLY;
