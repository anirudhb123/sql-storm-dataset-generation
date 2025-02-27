
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2452441 AND 2452450
    GROUP BY ss_store_sk, ss_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        MAX(cd.cd_demo_sk) AS max_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS num_unique_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
SalesWithCustomerDetails AS (
    SELECT 
        ss.ss_store_sk,
        ss.ss_item_sk,
        cs.c_customer_sk,
        cs.num_unique_customers,
        cs.avg_purchase_estimate,
        rs.total_quantity,
        rs.total_sales
    FROM RankedSales rs
    JOIN store_sales ss ON rs.ss_item_sk = ss.ss_item_sk
    LEFT JOIN CustomerStats cs ON ss.ss_customer_sk = cs.c_customer_sk
)
SELECT 
    COALESCE(swc.ss_store_sk, 'Unknown') AS store_id,
    COALESCE(item.i_item_id, 'No Item') AS item_id,
    COALESCE(swc.num_unique_customers, 0) AS number_of_customers,
    SUM(swc.total_sales) FILTER (WHERE swc.total_quantity IS NOT NULL) AS total_sales_amount,
    COUNT(DISTINCT swc.c_customer_sk) AS total_distinct_customers,
    AVG(swc.avg_purchase_estimate) OVER (PARTITION BY swc.ss_store_sk) AS avg_customer_purchase_estimate,
    CASE 
        WHEN COUNT(swc.c_customer_sk) > 100 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level
FROM SalesWithCustomerDetails swc
LEFT JOIN item ON swc.ss_item_sk = item.i_item_sk
GROUP BY 
    swc.ss_store_sk, 
    item.i_item_id
HAVING SUM(swc.total_sales) > 1000 
   OR (MAX(swc.total_quantity) IS NULL)
ORDER BY total_sales_amount DESC, engagement_level DESC;
