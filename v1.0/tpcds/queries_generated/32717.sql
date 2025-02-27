
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_order_number, ws_item_sk
),
FilteredSales AS (
    SELECT 
        ws_item_sk, 
        total_quantity,
        total_sales,
        sales_rank
    FROM 
        SalesCTE 
    WHERE 
        sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_credit_rating
),
AggregatedData AS (
    SELECT 
        fs.ws_item_sk,
        SUM(fs.total_quantity) AS total_sold,
        SUM(fs.total_sales) AS total_revenue,
        cd.gender,
        cd.marital_status,
        cd.credit_rating
    FROM 
        FilteredSales fs
    LEFT JOIN 
        CustomerDemographics cd ON fs.ws_item_sk = cd.cd_demo_sk
    GROUP BY 
        fs.ws_item_sk, cd.gender, cd.marital_status, cd.credit_rating
)
SELECT 
    ad.ws_item_sk,
    ad.total_sold,
    ad.total_revenue,
    COALESCE(ad.gender, 'Unknown') AS gender,
    COALESCE(ad.marital_status, 'Unknown') AS marital_status,
    COALESCE(ad.credit_rating, 'Not Rated') AS credit_rating
FROM 
    AggregatedData ad
WHERE 
    ad.total_sold > 100
ORDER BY 
    ad.total_revenue DESC
LIMIT 50
UNION ALL
SELECT 
    item.i_item_sk,
    0 AS total_sold,
    0 AS total_revenue,
    'Not Sold' AS gender,
    'Not Sold' AS marital_status,
    'Not Rated' AS credit_rating
FROM 
    item item
WHERE 
    item.i_item_sk NOT IN (SELECT ws_item_sk FROM FilteredSales)
ORDER BY 
    total_revenue DESC;
