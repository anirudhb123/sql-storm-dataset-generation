
WITH ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS average_net_profit
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 90 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_income_band_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_income_band_sk
),
SalesMetrics AS (
    SELECT 
        id.ws_item_sk,
        id.total_quantity_sold,
        id.total_sales,
        cd.gender,
        cd.income_band_sk,
        cm.customer_count
    FROM 
        ItemSales id
    LEFT JOIN 
        CustomerDemographics cd ON id.ws_item_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT ws_item_sk, COUNT(DISTINCT ws_bill_customer_sk) AS customer_count 
         FROM web_sales GROUP BY ws_item_sk) cm ON id.ws_item_sk = cm.ws_item_sk
)
SELECT 
    im.ws_item_sk,
    im.total_quantity_sold,
    im.total_sales,
    COALESCE(cd.customer_count, 0) AS unique_customers,
    CASE 
        WHEN im.total_sales > 10000 THEN 'High Performer' 
        WHEN im.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer' 
        ELSE 'Low Performer' 
    END AS performance_category
FROM 
    SalesMetrics im
JOIN 
    item i ON im.ws_item_sk = i.i_item_sk
WHERE 
    im.total_quantity_sold > 0 
ORDER BY 
    im.total_sales DESC
LIMIT 100;
