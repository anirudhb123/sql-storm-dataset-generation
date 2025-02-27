
WITH RECURSIVE CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ss.ticket_number) AS total_store_sales,
        SUM(ss.ext_sales_price) AS total_sales_amount,
        SUM(ss.ext_discount_amt) AS total_discounts,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_store_sales,
        cs.total_sales_amount,
        cs.total_discounts,
        CASE 
            WHEN cs.total_sales_amount IS NULL THEN 'No Sales Yet'
            WHEN cs.total_sales_amount > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_store_sales > 5
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_web_profit,
        AVG(ws.ws_sales_price) AS avg_web_sales_price
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
FinalReport AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.total_store_sales,
        hvc.total_sales_amount,
        hvc.total_discounts,
        hvc.customer_value_category,
        ss.total_web_profit,
        ss.avg_web_sales_price
    FROM 
        HighValueCustomers hvc
    FULL OUTER JOIN 
        SalesSummary ss ON hvc.total_store_sales > 5 OR hs.total_web_profit IS NOT NULL
)
SELECT 
    r.c_customer_id,
    r.customer_value_category,
    COALESCE(r.total_sales_amount, 0) AS sales_amount,
    COALESCE(r.total_web_profit, 0) AS web_profit,
    CASE 
        WHEN r.total_sales_amount IS NULL AND r.total_web_profit IS NULL THEN 'No Activity'
        ELSE 'Active Customer'
    END AS activity_status
FROM 
    FinalReport r
LEFT JOIN 
    customer c ON r.c_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_year IS NULL OR (c.c_birth_month IS NOT NULL AND c.c_birth_day IS NOT NULL AND c.c_birth_month = 12)
ORDER BY 
    r.total_sales_amount DESC NULLS LAST
LIMIT 50;
