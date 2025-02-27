
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS top_customers
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY s.s_store_sk, s.s_store_name
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.total_sales + COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) AS total_sales,
        sh.top_customers
    FROM SalesHierarchy sh
    LEFT JOIN store s ON sh.s_store_sk = s.s_store_sk
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE sh.total_sales > 10000
),
RankedSales AS (
    SELECT 
        store_sk,
        store_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesHierarchy
    WHERE total_sales IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd.cd_marital_status, 
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate, 
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate IS NOT NULL
    GROUP BY cd.cd_marital_status
)

SELECT 
    rs.store_name,
    rs.total_sales,
    rs.sales_rank,
    cd.avg_purchase_estimate,
    cd.female_count
FROM RankedSales rs
FULL OUTER JOIN CustomerDemographics cd ON rs.sales_rank <= 5
WHERE (cd.avg_purchase_estimate > 5000 OR cd.female_count > 100)
ORDER BY rs.total_sales DESC, cd.avg_purchase_estimate DESC;
