
WITH RECURSIVE Category_Hierarchy AS (
    SELECT c_category_id, c_category, c_parent_id 
    FROM category 
    WHERE c_parent_id IS NULL 
    UNION ALL 
    SELECT c.category_id, c.category, c.parent_id 
    FROM category c 
    INNER JOIN Category_Hierarchy ch ON c.parent_id = ch.c_category_id
),
Sales_Statistics AS (
    SELECT 
        SUM(ss_net_paid) AS total_sales, 
        AVG(ss_net_paid) AS avg_sales_price, 
        COUNT(DISTINCT ss_customer_sk) AS customer_count,
        c.customer_id
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
    WHERE ss.ss_sold_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY c.customer_id
),
Demographics AS (
    SELECT 
        cd.gender, 
        cd.education_status, 
        cd.marital_status, 
        d.total_sales,
        d.avg_sales_price
    FROM Sales_Statistics d 
    JOIN customer_demographics cd ON cd.cd_demo_sk = (
        SELECT c.c_current_cdemo_sk 
        FROM customer c 
        WHERE c.customer_id = d.customer_id
    )
),
Top_Demographics AS (
    SELECT 
        gender, 
        education_status, 
        marital_status, 
        SUM(total_sales) AS total_sales,
        COUNT(*) AS num_customers 
    FROM Demographics 
    GROUP BY gender, education_status, marital_status 
    ORDER BY total_sales DESC 
    LIMIT 10
)
SELECT 
    th.gender,
    th.education_status,
    th.marital_status,
    th.total_sales,
    th.num_customers,
    COUNT(DISTINCT r.reason_id) AS total_reasons
FROM Top_Demographics th
LEFT JOIN reason r ON r.reason_id IN (
      SELECT DISTINCT sr_reason_sk 
      FROM store_returns sr 
      WHERE sr_customer_sk IN (
          SELECT c.customer_sk 
          FROM customer c 
          WHERE c.c_current_cdemo_sk IS NOT NULL
      )
)
GROUP BY 
    th.gender, 
    th.education_status, 
    th.marital_status, 
    th.total_sales, 
    th.num_customers
HAVING th.total_sales > 5000
ORDER BY th.total_sales DESC;
