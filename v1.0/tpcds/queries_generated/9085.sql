
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank_sales <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ts.total_sales) AS total_sales_by_demo
    FROM 
        TopSellingItems ts
    JOIN 
        customer c ON c.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ts.ws_item_sk)
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_education_status,
    sd.total_sales_by_demo,
    RANK() OVER (ORDER BY sd.total_sales_by_demo DESC) AS sales_rank
FROM 
    SalesByDemographics sd
ORDER BY 
    sd.total_sales_by_demo DESC;
