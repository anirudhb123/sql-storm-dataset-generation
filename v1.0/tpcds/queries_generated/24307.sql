
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        AVG(ws_sales_price) AS avg_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_quantity, 
        rs.avg_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_purchase_estimate, cd.cd_credit_rating, cd.cd_dep_count
), 
SalesAndDemographics AS (
    SELECT 
        cs.ws_item_sk, 
        cs.total_quantity, 
        cs.avg_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.dependent_count,
        cd.customer_count
    FROM 
        TopSales cs
    LEFT JOIN 
        CustomerDemographics cd ON cs.ws_item_sk = cd.cd_demo_sk
)
SELECT 
    s.ws_item_sk,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.avg_sales_price, 0) AS avg_sales_price,
    COUNT(DISTINCT CASE WHEN cd.gender = 'F' THEN cd.customer_count END) AS female_customer_count,
    COUNT(DISTINCT CASE WHEN cd.gender = 'M' THEN cd.customer_count END) AS male_customer_count,
    SUM(CASE WHEN cd.marital_status = 'S' THEN customer_count ELSE 0 END) AS single_customers,
    SUM(CASE WHEN cd.marital_status = 'M' THEN customer_count ELSE 0 END) AS married_customers
FROM 
    SalesAndDemographics s
LEFT JOIN 
    customer_demographics cd ON s.ws_item_sk = cd.cd_demo_sk
GROUP BY 
    s.ws_item_sk
HAVING 
    SUM(s.total_quantity) > (SELECT AVG(total_quantity) FROM TopSales)
ORDER BY 
    total_quantity DESC;
