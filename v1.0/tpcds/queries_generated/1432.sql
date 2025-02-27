
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_ticket_number,
        ss_sales_price,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY ss_sales_price DESC) AS price_rank,
        cs_sales_price AS catalog_sales_price,
        wr_return_amt,
        wr_return_quantity,
        wr_order_number AS web_return_order_number
    FROM 
        store_sales
    LEFT JOIN 
        catalog_sales ON ss_item_sk = cs_item_sk
    LEFT JOIN 
        web_returns ON ss_ticket_number = wr_order_number
    WHERE 
        ss_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_year = 2022) 
        AND ss_sales_price > 20
),
TotalReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_return_quantity) AS total_return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        hd_income_band_sk,
        RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN 
        household_demographics ON c_customer_sk = hd_demo_sk
)
SELECT 
    sd.ss_store_sk,
    cd.cd_gender,
    COUNT(DISTINCT sd.ss_ticket_number) AS total_sales,
    SUM(sd.ss_sales_price) AS total_sales_price,
    tr.total_return_amt,
    tr.total_return_count,
    CASE 
        WHEN SUM(sd.ss_sales_price) > 1000 THEN 'High Value'
        WHEN SUM(sd.ss_sales_price) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    RankedSales sd
JOIN 
    CustomerDemographics cd ON sd.ss_ticket_number = cd.c_customer_sk
LEFT JOIN 
    TotalReturns tr ON cd.c_customer_sk = tr.wr_returning_customer_sk
WHERE 
    sd.price_rank <= 5
GROUP BY 
    sd.ss_store_sk, cd.cd_gender
ORDER BY 
    total_sales_price DESC, cd.cd_gender;
