
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i.i_item_sk AS item_id, 
        i.i_item_desc AS item_description, 
        NULL AS parent_id
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND i.i_rec_end_date >= CURRENT_DATE
    
    UNION ALL
    
    SELECT 
        isub.i_item_sk, 
        isub.i_item_desc, 
        ih.item_id
    FROM 
        item isub
    JOIN 
        ItemHierarchy ih ON isub.i_item_sk = ih.item_id
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_income_band_sk
)
SELECT 
    ih.item_id,
    ih.item_description,
    sd.total_quantity,
    sd.total_sales,
    cd.customer_count,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    ItemHierarchy ih
LEFT JOIN 
    SalesData sd ON ih.item_id = sd.ws_item_sk
JOIN 
    CustomerDemographics cd ON cd.customer_count > 10
LEFT JOIN 
    income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    sd.total_sales IS NOT NULL AND
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
ORDER BY 
    sd.total_sales DESC,
    cd.customer_count ASC;
