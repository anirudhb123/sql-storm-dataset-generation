
WITH HistoricalSales AS (
    SELECT 
        s_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        MAX(ss_sold_date_sk) AS last_sold_date
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 365 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        s_store_sk, ss_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemPopularity AS (
    SELECT 
        i.i_item_sk,
        i.i_category,
        COUNT(DISTINCT hs.s_store_sk) AS store_count,
        AVG(hs.total_sales) AS avg_sales_per_store
    FROM 
        HistoricalSales hs
    JOIN 
        item i ON hs.ss_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk, i.i_category
),
TopItems AS (
    SELECT 
        ip.i_item_sk,
        ip.i_category,
        ip.store_count,
        ip.avg_sales_per_store,
        RANK() OVER (PARTITION BY ip.i_category ORDER BY ip.avg_sales_per_store DESC) AS sales_rank
    FROM 
        ItemPopularity ip
),
FinalReport AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ti.i_category,
        ti.store_count,
        ti.avg_sales_per_store,
        COUNT(DISTINCT cd.c_customer_sk) AS customer_count
    FROM 
        CustomerDemographics cd
    JOIN 
        TopItems ti ON ti.store_count > 10 -- Only include items sold in more than 10 stores
    WHERE 
        ti.sales_rank <= 10 -- Top 10 items by category
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ti.i_category, ti.store_count, ti.avg_sales_per_store
)
SELECT 
    f.cd_gender,
    f.cd_marital_status,
    f.cd_education_status,
    f.i_category,
    f.store_count,
    f.avg_sales_per_store,
    f.customer_count
FROM 
    FinalReport f
ORDER BY 
    f.i_category, f.store_count DESC;
