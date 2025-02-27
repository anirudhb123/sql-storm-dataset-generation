
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
), TopSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        total_quantity, 
        total_sales
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 10
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
        JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
), DetailedSales AS (
    SELECT 
        ts.ws_sold_date_sk,
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        TopSales ts
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk IN (
            SELECT c.c_current_cdemo_sk
            FROM customer c 
            WHERE c.c_customer_sk IN (
                SELECT DISTINCT ws_bill_customer_sk 
                FROM web_sales
                WHERE ws_sold_date_sk = ts.ws_sold_date_sk
            )
        )
), AggregatedResults AS (
    SELECT 
        ws_item_sk,
        COUNT(DISTINCT ws_sold_date_sk) AS sale_days_count,
        AVG(total_sales) AS average_sales,
        SUM(total_quantity) AS total_quantity_sold,
        COUNT(DISTINCT cd_gender) AS unique_genders,
        COUNT(DISTINCT cd_marital_status) AS unique_marital_statuses
    FROM 
        DetailedSales
    GROUP BY 
        ws_item_sk
)
SELECT 
    ar.ws_item_sk,
    ar.sale_days_count,
    ar.average_sales,
    ar.total_quantity_sold,
    ar.unique_genders,
    ar.unique_marital_statuses
FROM 
    AggregatedResults ar
WHERE 
    ar.total_quantity_sold > 100
ORDER BY 
    ar.average_sales DESC;
