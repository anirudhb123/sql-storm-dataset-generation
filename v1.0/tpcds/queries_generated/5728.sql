
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS total_returned_items,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        h.hd_income_band_sk,
        h.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
CombiningData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        h.hd_income_band_sk,
        h.hd_buy_potential,
        COALESCE(cr.total_returned_items, 0) AS total_returned_items,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(sr.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(sr.total_orders, 0) AS total_orders,
        COALESCE(sr.total_quantity_sold, 0) AS total_quantity_sold
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebSalesSummary sr ON cd.c_customer_sk = sr.ws_bill_customer_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    hd_income_band_sk,
    hd_buy_potential,
    AVG(total_returned_items) AS avg_returned_items,
    AVG(total_returned_amount) AS avg_returned_amount,
    AVG(total_sales_amount) AS avg_sales_amount,
    AVG(total_orders) AS avg_orders,
    AVG(total_quantity_sold) AS avg_quantity_sold
FROM 
    CombiningData
GROUP BY 
    cd_gender, cd_marital_status, hd_income_band_sk, hd_buy_potential
ORDER BY 
    avg_sales_amount DESC;
