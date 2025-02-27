
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk
    FROM 
        customer_demographics
),
IncomeBands AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound
    FROM 
        income_band
),
JointData AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        SalesData sd
    JOIN 
        customer c ON c.c_current_cdemo_sk = (SELECT cd_demo_sk FROM customer_demographics ORDER BY RANDOM() LIMIT 1)
    JOIN 
        CustomerDemographics cd ON c.c_customer_sk = cd.cd_demo_sk
    JOIN 
        IncomeBands ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    COUNT(*) AS total_records,
    AVG(total_sales) AS average_sales,
    SUM(total_quantity) AS total_quantity_sold,
    COUNT(DISTINCT ws_item_sk) AS unique_items_sold,
    cd_gender,
    cd_marital_status,
    ib_lower_bound,
    ib_upper_bound
FROM 
    JointData
GROUP BY 
    cd_gender, cd_marital_status, ib_lower_bound, ib_upper_bound
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;
