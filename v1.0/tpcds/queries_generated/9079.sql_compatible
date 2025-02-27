
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 
        (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk, 
        ri.total_sales, 
        i.i_item_desc, 
        i.i_brand, 
        i.i_current_price
    FROM 
        RankedSales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
)
SELECT 
    ti.i_brand,
    ti.i_item_desc,
    ti.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(cd.customer_count) AS total_customers
FROM 
    TopItems ti
JOIN 
    CustomerDemographics cd ON cd.cd_purchase_estimate > 1000
GROUP BY 
    ti.i_brand, ti.i_item_desc, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_sales DESC, total_customers DESC;
