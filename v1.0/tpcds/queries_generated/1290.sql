
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.customer_sk,
        sr.return_quantity,
        COALESCE(sr.return_amt, 0) AS return_amt,
        COALESCE(sr.return_ship_cost, 0) AS return_ship_cost,
        ROW_NUMBER() OVER (PARTITION BY sr.customer_sk ORDER BY sr.returned_date_sk DESC) AS rn
    FROM 
        store_returns sr
), CustomerDemographics AS (
    SELECT 
        cd.demo_sk,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        COUNT(c.c_customer_sk) AS num_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        cd.demo_sk, cd.gender, cd.marital_status, cd.education_status
), SalesData AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        EXISTS (
            SELECT 1
            FROM CustomerReturns cr
            WHERE cr.customer_sk = ws.bill_customer_sk
            HAVING SUM(cr.return_quantity) > 5
        )
    GROUP BY 
        ws.web_site_sk
), IncomeStats AS (
    SELECT 
        ib.income_band_sk,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE 
        cd.gender = 'M' 
        AND cd.marital_status = 'S'
    GROUP BY 
        ib.income_band_sk
)
SELECT 
    cd.gender,
    cd.marital_status,
    cd.education_status,
    SUM(sd.total_net_profit) AS total_net_profit_by_site,
    COUNT(sd.total_orders) AS total_orders_by_site,
    is.avg_purchase_estimate
FROM 
    CustomerDemographics cd
LEFT JOIN 
    SalesData sd ON cd.num_customers = sd.web_site_sk
LEFT JOIN 
    IncomeStats is ON cd.demo_sk = is.income_band_sk
WHERE 
    cd.num_customers > 10 
GROUP BY 
    cd.gender, cd.marital_status, cd.education_status, is.avg_purchase_estimate
HAVING 
    SUM(sd.total_net_profit) > 10000
ORDER BY 
    total_net_profit_by_site DESC;
