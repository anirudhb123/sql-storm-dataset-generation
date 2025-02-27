
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
),
QualifiedCustomers AS (
    SELECT 
        sh.customer_sk,
        sh.total_sales,
        sh.total_orders,
        DENSE_RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        SalesHierarchy sh
    WHERE 
        sh.total_orders >= 5
),
MarketInsights AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COALESCE(NULLIF(AVG(CASE WHEN w.w_warehouse_sq_ft IS NOT NULL THEN w.w_warehouse_sq_ft END), 0), 
                 (SELECT AVG(w2.w_warehouse_sq_ft) FROM warehouse w2)) AS avg_warehouse_sq_ft
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk OR ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        c.c_customer_id, ca.ca_city
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 0 OR COUNT(DISTINCT ss.ss_ticket_number) > 0
)
SELECT 
    q.customer_sk,
    q.total_sales,
    q.total_orders,
    m.c_customer_id,
    m.ca_city,
    m.total_web_sales,
    m.total_store_sales,
    CASE 
        WHEN q.sales_rank <= 10 THEN 'Top Performer'
        WHEN q.sales_rank > 10 AND q.sales_rank <= 50 THEN 'Mid Performer'
        ELSE 'Under Performer'
    END AS performance_category,
    m.avg_warehouse_sq_ft
FROM 
    QualifiedCustomers q
JOIN 
    MarketInsights m ON q.customer_sk = m.c_customer_id
WHERE 
    q.sales_rank NOT BETWEEN 21 AND 30 OR m.total_web_sales IS NOT NULL
ORDER BY 
    q.total_sales DESC, m.ca_city ASC;
