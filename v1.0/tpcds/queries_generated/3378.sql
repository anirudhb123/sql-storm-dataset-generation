
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_web_site_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_web_site_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_web_site_sk,
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    w.w_warehouse_name,
    tsi.ws_item_sk,
    tsi.total_quantity,
    tsi.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.num_customers,
    CASE 
        WHEN cd.num_customers > 100 THEN 'High'
        WHEN cd.num_customers BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS customer_potential
FROM 
    TopSellingItems tsi
JOIN 
    warehouse w ON w.w_warehouse_sk = (SELECT w_warehouse_sk FROM inventory WHERE inv_item_sk = tsi.ws_item_sk LIMIT 1)
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk IN (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk IS NOT NULL)
ORDER BY 
    tsi.total_sales DESC, 
    w.w_warehouse_name, 
    cd.cd_gender;
