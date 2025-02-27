
WITH RevenueData AS (
    SELECT 
        w.warehouse_id,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_order_number) AS total_orders
    FROM 
        store_sales
    JOIN 
        warehouse w ON ss_store_sk = w.warehouse_sk
    WHERE 
        ss_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_moy IN (5, 6)
        )
    GROUP BY 
        w.warehouse_id
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
)
SELECT 
    rd.warehouse_id,
    rd.total_sales,
    rd.total_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY rd.total_profit DESC) AS rank_within_gender
FROM 
    RevenueData rd
LEFT JOIN 
    CustomerDemographics cd ON cd.customer_count > 100
WHERE 
    rd.total_sales > 5000
ORDER BY 
    rd.total_profit DESC, cd.cd_gender;
