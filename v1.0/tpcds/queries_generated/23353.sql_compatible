
WITH RecursiveSales AS (
    SELECT 
        ss.s_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.s_sold_date_sk) AS rn
    FROM 
        store_sales ss
    WHERE 
        ss.s_sold_date_sk BETWEEN 1000 AND 2000
        AND ss.ss_quantity IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        rs.s_sold_date_sk,
        SUM(rs.ss_quantity) AS total_quantity,
        SUM(rs.ss_net_profit) AS total_profit
    FROM 
        RecursiveSales rs
    GROUP BY 
        rs.s_sold_date_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(NULLIF(cd.cd_credit_rating, ''), 'Unknown') AS cd_credit_rating, 
        CASE 
            WHEN cd.cd_dep_count > 2 THEN 'High' 
            ELSE 'Low' 
        END AS dependency_level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ca.ca_city,
    SUM(as.total_quantity) AS total_purchased,
    AVG(as.total_profit) AS avg_profit,
    COUNT(DISTINCT ci.c_customer_sk) AS customers_count,
    CASE 
        WHEN SUM(as.total_quantity) > 100 THEN 'Frequent Buyer' 
        ELSE 'Occasional Buyer' 
    END AS buyer_type
FROM 
    CustomerInfo ci
LEFT JOIN 
    store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    AggregatedSales as ON ss.s_sold_date_sk = as.s_sold_date_sk
LEFT JOIN 
    customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_purchase_estimate, 
    ci.cd_credit_rating, 
    ca.ca_city
HAVING 
    COUNT(DISTINCT ss.ss_item_sk) > 10
    OR ci.cd_gender IS NULL
    OR ci.cd_marital_status = 'S'
ORDER BY 
    avg_profit DESC
LIMIT 5;
