
WITH RankedReturns AS (
    SELECT 
        cr_returned_date_sk,
        cr_item_sk,
        COUNT(cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_tax) AS total_return_tax,
        ROW_NUMBER() OVER (PARTITION BY cr_item_sk ORDER BY SUM(cr_return_amount) DESC) AS rn
    FROM 
        catalog_returns
    GROUP BY 
        cr_returned_date_sk, cr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_income_band_sk BETWEEN 1 AND 5 THEN 'Low Income'
            WHEN cd_income_band_sk BETWEEN 6 AND 10 THEN 'Middle Income'
            WHEN cd_income_band_sk BETWEEN 11 AND 15 THEN 'High Income'
            ELSE 'Unknown'
        END AS income_band
    FROM 
        household_demographics
    JOIN 
        income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
),
SalesWithShipping AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        sm.sm_type,
        SUM(ws.ws_net_paid_inc_ship) AS total_net_paid_with_shipping
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                                   (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, 
        ws.ws_item_sk, 
        sm.sm_type
),
FinalResults AS (
    SELECT 
        cr.cr_item_sk,
        COALESCE(rr.total_returns, 0) AS return_count,
        COALESCE(rr.total_return_amount, 0) AS return_amount,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        cd.income_band,
        RANK() OVER (ORDER BY COALESCE(ss.total_net_profit, 0) DESC) AS profit_rank
    FROM 
        RankedReturns rr
    FULL OUTER JOIN 
        SalesWithShipping ss ON rr.cr_item_sk = ss.ws_item_sk
    JOIN 
        item i ON rr.cr_item_sk = i.i_item_sk
    LEFT JOIN 
        CustomerDemographics cd ON i.i_brand_id = cd.cd_demo_sk
)

SELECT 
    fr.cr_item_sk,
    fr.return_count,
    fr.return_amount,
    fr.total_sales,
    fr.total_net_profit,
    fr.income_band,
    fr.profit_rank
FROM 
    FinalResults fr
WHERE 
    fr.return_count > 5 OR fr.total_sales > 100
ORDER BY 
    fr.profit_rank;
