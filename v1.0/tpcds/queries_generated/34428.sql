
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_cdemo_sk,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_hour_of_registration >= 9 -- Only consider customers registered after 9 AM

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE 
        ch.level < 3 -- Limit depth to 3 levels
),
SalesData AS (
    SELECT 
        ws.ws_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        CustomerHierarchy ch ON ws.ws_ship_customer_sk = ch.c_customer_sk
    GROUP BY 
        ws.ws_customer_sk
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        SalesData
),
CustomerStatistics AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        CASE WHEN sd.order_count > 5 THEN 'High' ELSE 'Low' END AS customer_category
    FROM 
        CustomerHierarchy ch
    LEFT JOIN 
        SalesData sd ON ch.c_customer_sk = sd.ws_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.customer_category,
    CASE 
        WHEN cs.total_sales > (SELECT avg_sales FROM AverageSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison
FROM 
    CustomerStatistics cs
ORDER BY 
    cs.total_sales DESC
LIMIT 50;
