
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_sold,
        SUM(ss_net_paid) AS total_revenue,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
    UNION ALL
    SELECT 
        s.ss_item_sk,
        s.total_sold + c.total_sold,
        s.total_revenue + c.total_revenue,
        c.level + 1
    FROM 
        SalesCTE c
    JOIN 
        store_sales s ON c.ss_item_sk = s.ss_item_sk
    WHERE 
        c.level < 5
),
SalesSummary AS (
    SELECT 
        s.ss_item_sk,
        COALESCE(SUM(s.ss_quantity), 0) AS total_quantity,
        COALESCE(SUM(s.ss_net_paid), 0) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(s.ss_net_paid), 0) DESC) AS sales_rank
    FROM 
        store_sales s
    GROUP BY 
        s.ss_item_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        COUNT(o.ss_ticket_number) AS purchase_count,
        SUM(o.ss_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        store_sales o ON c.c_customer_sk = o.ss_customer_sk
    LEFT JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, d.cd_gender
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.purchase_count,
    cs.total_spent,
    ss.total_quantity,
    ss.total_sales,
    CASE 
        WHEN cs.total_spent >= 1000 THEN 'High Value'
        WHEN cs.total_spent >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    ss.sales_rank
FROM 
    CustomerSummary cs
JOIN 
    SalesSummary ss ON cs.c_customer_sk = ss.ss_item_sk
WHERE 
    cs.purchase_count > (SELECT AVG(purchase_count) FROM CustomerSummary)
    AND cs.cd_gender IS NOT NULL
ORDER BY 
    customer_value DESC, total_spent DESC
LIMIT 100;
