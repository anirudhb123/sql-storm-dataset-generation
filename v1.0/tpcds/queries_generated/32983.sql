
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ss.ss_item_sk,
        ss.ss_sales_price,
        ss.ss_quantity,
        1 AS level
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    
    UNION ALL
    
    SELECT 
        ss.ss_item_sk,
        ss.ss_sales_price * 0.9 AS ss_sales_price,
        ss.ss_quantity * 2 AS ss_quantity,
        sh.level + 1
    FROM 
        store_sales ss
    JOIN 
        SalesHierarchy sh ON ss.ss_item_sk = sh.ss_item_sk
    WHERE 
        sh.level < 5
), 
AggregateSales AS (
    SELECT 
        sh.ss_item_sk,
        SUM(sh.ss_sales_price) AS total_sales,
        SUM(sh.ss_quantity) AS total_quantity
    FROM 
        SalesHierarchy sh
    GROUP BY 
        sh.ss_item_sk
),
CustomerSpending AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
DemographicSpending AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cs.total_spent) AS avg_spent
    FROM 
        CustomerSpending cs
    LEFT JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ca.ca_city,
    SUM(ds.avg_spent) AS avg_spending,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    customer_address ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    DemographicSpending ds ON c.c_current_cdemo_sk = ds.cd_demo_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ds.avg_spent) IS NOT NULL
ORDER BY 
    avg_spending DESC
LIMIT 10;
