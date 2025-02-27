
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT
        item.i_item_id,
        SUM(rs.ws_ext_sales_price) AS total_sales,
        AVG(rs.ws_sales_price) AS avg_sales_price,
        COUNT(rs.ws_order_number) AS total_orders
    FROM 
        RankedSales rs
    JOIN 
        item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.price_rank <= 3
    GROUP BY 
        item.i_item_id
),
SalesComparison AS (
    SELECT 
        i_item_id,
        total_sales,
        avg_sales_price,
        CASE 
            WHEN total_orders > 100 THEN 'High'
            WHEN total_orders BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS order_volume
    FROM 
        SalesSummary
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
SalesWithDemographics AS (
    SELECT 
        sc.i_item_id,
        sc.total_sales,
        sc.avg_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.customer_count
    FROM 
        SalesComparison sc
    LEFT JOIN 
        CustomerDemographics cd ON cd.customer_count > 10
)
SELECT 
    swd.i_item_id,
    swd.total_sales,
    swd.avg_sales_price,
    COALESCE(cd_gender, 'Unknown') AS cd_gender,
    COALESCE(cd_marital_status, 'Unknown') AS cd_marital_status,
    SUM(ss.ss_quantity) AS total_store_sales,
    CASE 
        WHEN AVG(swd.avg_sales_price) > 100 THEN 'Expensive'
        WHEN AVG(swd.avg_sales_price) BETWEEN 50 AND 100 THEN 'Moderate'
        ELSE 'Cheap'
    END AS price_category
FROM 
    SalesWithDemographics swd
LEFT JOIN 
    store_sales ss ON swd.i_item_id = ss.ss_item_sk
GROUP BY 
    swd.i_item_id, 
    swd.total_sales, 
    swd.avg_sales_price, 
    cd_gender, 
    cd_marital_status
HAVING 
    SUM(ss.ss_quantity) > 0 OR COUNT(ss.ss_item_sk) IS NULL
ORDER BY 
    total_sales DESC, 
    i_item_id
LIMIT 50;
