
WITH RecursiveCTE AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.cs_ext_sales_price DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_credit_rating IS NOT NULL
),
AggregateData AS (
    SELECT 
        r.c_customer_id,
        COUNT(DISTINCT r.c_first_name) AS distinct_first_names,
        COUNT(DISTINCT r.c_last_name) AS distinct_last_names,
        AVG(ss.ss_sales_price) AS average_sales_price,
        MAX(cs.cs_net_profit) AS max_catalog_profit
    FROM 
        RecursiveCTE r
    LEFT JOIN 
        store_sales ss ON r.c_customer_id = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON r.c_customer_id = cs.cs_bill_customer_sk
    WHERE 
        r.rnk = 1
    GROUP BY 
        r.c_customer_id
),
FinalSelection AS (
    SELECT 
        ad.*, 
        CASE 
            WHEN ad.average_sales_price IS NULL THEN 'No Sales'
            ELSE 'Sales Exist' 
        END AS sales_status,
        MAX(CASE 
            WHEN ad.max_catalog_profit IS NULL THEN 0 
            ELSE ad.max_catalog_profit 
        END) AS adjusted_max_catalog_profit
    FROM 
        AggregateData ad
    GROUP BY 
        ad.c_customer_id, ad.distinct_first_names, ad.distinct_last_names, ad.average_sales_price
)
SELECT 
    fs.c_customer_id,
    fs.distinct_first_names,
    fs.distinct_last_names,
    COALESCE(fs.average_sales_price, 0.00) AS final_average_sales_price,
    fs.sales_status,
    fs.adjusted_max_catalog_profit
FROM 
    FinalSelection fs
ORDER BY 
    fs.final_average_sales_price DESC 
LIMIT 100
OFFSET 50;

-- The query above may not suffer from unusual cases with nested CTEs, complex joins, and it also uses a "sales_status" logic based on NULL checks with aggregation while having logical partitions and ranking.
