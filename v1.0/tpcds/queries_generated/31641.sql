
WITH RECURSIVE CustomerSalesCTE AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_id
    UNION ALL
    SELECT 
        c.c_customer_id,
        SUM(total_net_paid * 1.1) AS total_net_paid,
        store_sales_count + 1,
        web_sales_count + 1,
        catalog_sales_count + 1
    FROM CustomerSalesCTE 
    JOIN customer c ON CustomerSalesCTE.c_customer_id = c.c_customer_id
    WHERE total_net_paid > 1000
    GROUP BY c.c_customer_id
),
SalesRanked AS (
    SELECT 
        c.c_customer_id,
        total_net_paid,
        store_sales_count,
        web_sales_count,
        catalog_sales_count,
        RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank
    FROM CustomerSalesCTE
)
SELECT 
    s.c_customer_id,
    s.total_net_paid,
    s.store_sales_count,
    s.web_sales_count,
    s.catalog_sales_count
FROM SalesRanked s
WHERE s.sales_rank <= 10
AND EXISTS (
    SELECT 1 
    FROM customer_demographics cd 
    WHERE cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = s.c_customer_id)
    AND cd.cd_marital_status = 'M'
)
ORDER BY s.total_net_paid DESC;
