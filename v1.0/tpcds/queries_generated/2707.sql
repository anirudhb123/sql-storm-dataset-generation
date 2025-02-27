
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.w_warehouse_name, d.d_year
), 
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_returned_date_sk) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    s.w_warehouse_name,
    ss.d_year,
    ss.total_quantity,
    ss.total_net_profit,
    COUNT(DISTINCT cr.sr_customer_sk) AS customer_return_count,
    SUM(cr.total_return_amount) AS total_return_to_customers,
    ARRAY_AGG(DISTINCT cd.cd_gender) AS customer_genders
FROM 
    SalesSummary ss
LEFT JOIN 
    CustomerReturns cr ON ss.w_warehouse_name = (SELECT w.w_warehouse_name FROM warehouse w WHERE w.w_warehouse_sk = ss.total_quantity)
LEFT JOIN 
    CustomerDemographics cd ON cr.sr_customer_sk = cd.cd_demo_sk
WHERE 
    ss.total_net_profit > (SELECT AVG(total_net_profit) FROM SalesSummary)
GROUP BY 
    s.w_warehouse_name, ss.d_year
ORDER BY 
    ss.total_net_profit DESC;
