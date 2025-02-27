
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
DemographicSales AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cs.total_spent) AS avg_spent,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesPerformance AS (
    SELECT 
        ds.cd_gender,
        ds.cd_marital_status,
        ds.avg_spent,
        ds.customer_count,
        RANK() OVER (ORDER BY ds.avg_spent DESC) AS rank_by_spent
    FROM 
        DemographicSales ds
)
SELECT 
    sp.cd_gender,
    sp.cd_marital_status,
    sp.avg_spent,
    sp.customer_count,
    sp.rank_by_spent,
    CASE 
        WHEN sp.rank_by_spent <= 10 THEN 'Top Performer'
        WHEN sp.rank_by_spent <= 20 THEN 'Above Average'
        WHEN sp.rank_by_spent <= 50 THEN 'Average Performer'
        ELSE 'Below Average'
    END AS performance_category
FROM 
    SalesPerformance sp
ORDER BY 
    sp.rank_by_spent;
