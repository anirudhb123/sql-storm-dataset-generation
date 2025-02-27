
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS sales_count,
        SUM(ws_coupon_amt) AS total_coupons,
        AVG(ws_net_profit) AS avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        hd_income_band_sk,
        d.cacustomer_sk, 
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_description
    FROM 
        customer_demographics AS cd
    LEFT JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
TopCustomers AS (
    SELECT 
        cs.ws_bill_customer_sk,
        cs.total_sales,
        cd.gender_description,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        SalesSummary AS cs
    JOIN 
        CustomerDemographics AS cd ON cs.ws_bill_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.sales_count > 5
)
SELECT 
    tcs.ws_bill_customer_sk,
    tcs.total_sales,
    tcs.gender_description,
    COALESCE(COUNT(sr_item_sk), 0) AS returned_items,
    COALESCE(SUM(sr_return_amt), 0) AS total_returned_amount,
    case when sum(NULLIF(tcs.total_sales, 0)) = 0 then 0 else
    sum(CASE WHEN tcs.total_sales > 1000 THEN tcs.total_sales ELSE 0 END) END AS high_value_sales
FROM 
    TopCustomers AS tcs
LEFT JOIN 
    store_returns AS sr ON tcs.ws_bill_customer_sk = sr.sr_customer_sk
WHERE 
    tcs.rank <= 10
GROUP BY 
    tcs.ws_bill_customer_sk, tcs.total_sales, tcs.gender_description
ORDER BY 
    tcs.total_sales DESC;
