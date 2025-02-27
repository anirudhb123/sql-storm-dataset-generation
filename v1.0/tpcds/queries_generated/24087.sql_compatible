
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
TotalReturns AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returned
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesWithDemographics AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        cdem.c_customer_id,
        cdem.cd_gender,
        cdem.income_band
    FROM 
        web_sales ws
    JOIN 
        CustomerDemographics cdem ON ws.ws_bill_customer_sk = cdem.c_customer_id
),
AggregatedData AS (
    SELECT 
        swd.ws_item_sk, 
        swd.c_customer_id, 
        SUM(swd.ws_sales_price) AS total_sales,
        MAX(rt.total_returned) AS max_returned,
        COUNT(*) AS sales_count
    FROM 
        SalesWithDemographics swd
    LEFT JOIN 
        TotalReturns rt ON swd.ws_item_sk = rt.wr_item_sk
    GROUP BY 
        swd.ws_item_sk, swd.c_customer_id
)
SELECT 
    ad.ws_item_sk, 
    ad.c_customer_id,
    ad.total_sales,
    ad.max_returned,
    ad.sales_count,
    CASE 
        WHEN ad.max_returned IS NULL THEN 'No Returns'
        WHEN ad.max_returned > 0 AND ad.total_sales < 100 THEN 'Frequent Returns'
        ELSE 'Normal Sales'
    END AS sales_category,
    STRING_AGG(DISTINCT cdem.cd_gender) AS distinct_genders
FROM 
    AggregatedData ad
JOIN 
    CustomerDemographics cdem ON ad.c_customer_id = cdem.c_customer_id
WHERE 
    ad.total_sales > 0 
GROUP BY 
    ad.ws_item_sk, ad.c_customer_id, ad.total_sales, ad.max_returned, ad.sales_count
HAVING 
    COUNT(CASE WHEN cdem.cd_marital_status = 'M' THEN 1 END) > 0 
ORDER BY 
    ad.total_sales DESC
LIMIT 100;
