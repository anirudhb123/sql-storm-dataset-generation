
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.order_number) AS web_order_count,
        COUNT(DISTINCT sr.ticket_number) AS store_return_count,
        AVG(sr.return_amt) AS avg_store_return_amt
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_id
), StorePerformance AS (
    SELECT 
        s.s_store_id,
        SUM(ss.net_paid) AS total_store_sales,
        AVG(ss.net_profit) AS avg_store_net_profit,
        COUNT(DISTINCT ss.ticket_number) AS total_transactions
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.store_sk
    GROUP BY 
        s.s_store_id
), DemographicsAnalysis AS (
    SELECT 
        cd.gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cs.total_web_sales) AS total_sales_web,
        SUM(sp.total_store_sales) AS total_sales_store
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        CustomerSales cs ON c.c_customer_id = cs.c_customer_id
    LEFT JOIN 
        StorePerformance sp ON c.c_current_addr_sk = sp.s_store_id
    GROUP BY 
        cd.gender
)
SELECT 
    gender,
    customer_count,
    total_sales_web,
    total_sales_store,
    (total_sales_web + total_sales_store) AS total_combined_sales
FROM 
    DemographicsAnalysis
ORDER BY 
    total_combined_sales DESC;
