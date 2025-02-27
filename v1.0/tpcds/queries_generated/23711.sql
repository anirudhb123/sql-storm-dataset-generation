
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
SalesRanking AS (
    SELECT 
        c.c_customer_id,
        total_store_sales,
        total_web_sales,
        store_transactions,
        web_transactions,
        RANK() OVER (PARTITION BY CASE 
                                      WHEN total_store_sales > total_web_sales THEN 'Store' 
                                      WHEN total_web_sales > total_store_sales THEN 'Web' 
                                      ELSE 'Equal' 
                                   END 
                     ORDER BY total_store_sales + total_web_sales DESC) AS sales_rank
    FROM CustomerSales c
),
GenderDemographics AS (
    SELECT 
        cd.cd_gender,
        AVG(COALESCE(cs.total_store_sales, 0)) AS avg_store_sales,
        AVG(COALESCE(cs.total_web_sales, 0)) AS avg_web_sales,
        COUNT(cs.c_customer_id) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN CustomerSales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    g.cd_gender,
    AVG(g.avg_store_sales) AS avg_store_sales,
    AVG(g.avg_web_sales) AS avg_web_sales,
    SUM(CASE WHEN g.customer_count > 10 THEN g.customer_count END) AS high_engagement_customers,
    (SELECT COUNT(DISTINCT c.c_customer_id) 
     FROM customer c 
     WHERE c.c_birth_year BETWEEN 1980 AND 2000) AS millennial_count,
    (SELECT MAX(total_web_sales) 
     FROM SalesRanking 
     WHERE sales_rank <= 10) AS top_web_sales
FROM GenderDemographics g
GROUP BY g.cd_gender
HAVING COUNT(g.customer_count) > 5
ORDER BY g.cd_gender;
