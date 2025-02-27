
WITH SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3)
    GROUP BY 
        ws.ws_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 15000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_band
    FROM 
        customer_demographics cd
),
ReturnSummary AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
FinalReport AS (
    SELECT 
        cs.cd_demo_sk,
        cs.total_quantity,
        cs.total_net_profit,
        cs.total_discount,
        CASE 
            WHEN rs.total_returns IS NULL THEN 0
            ELSE rs.total_returns
        END AS total_returns,
        CASE 
            WHEN rs.total_return_amount IS NULL THEN 0
            ELSE rs.total_return_amount
        END AS total_return_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.purchase_estimate_band
    FROM 
        SalesSummary cs
    JOIN 
        CustomerDemographics cd ON cs.ws_sold_date_sk = cd.cd_demo_sk
    LEFT JOIN 
        ReturnSummary rs ON cs.ws_quantity = rs.total_returns
)
SELECT 
    f.cd_demo_sk,
    f.total_quantity,
    f.total_net_profit,
    f.total_discount,
    f.total_returns,
    f.total_return_amount,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_education_status,
    f.purchase_estimate_band
FROM 
    FinalReport f
WHERE 
    f.total_net_profit > 10000
ORDER BY 
    f.total_net_profit DESC
LIMIT 100;
