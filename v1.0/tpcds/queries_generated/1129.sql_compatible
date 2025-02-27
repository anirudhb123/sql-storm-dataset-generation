
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(NULLIF(SUM(ws.ws_net_paid), 0), 0) + 
        COALESCE(NULLIF(SUM(cs.cs_net_paid), 0), 0) + 
        COALESCE(NULLIF(SUM(ss.ss_net_paid), 0), 0)) AS overall_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY overall_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    rs.c_customer_sk,
    rs.c_first_name,
    rs.c_last_name,
    rs.total_web_sales,
    rs.total_catalog_sales,
    rs.total_store_sales,
    rs.overall_sales,
    (SELECT COUNT(*) FROM customer c2 WHERE c2.c_current_addr_sk IS NOT NULL) AS total_active_customers,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top Performer'
        WHEN rs.sales_rank <= 50 THEN 'Mid Tier'
        ELSE 'Low Performer'
    END AS performance_tier
FROM 
    RankedSales rs
WHERE 
    rs.overall_sales > (SELECT AVG(overall_sales) FROM CustomerSales)
ORDER BY 
    rs.overall_sales DESC;
