
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rnk
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
CustomerIncome AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesData AS (
    SELECT 
        CASE 
            WHEN ws_ship_date_sk IS NULL THEN 'UNKNOWN'
            ELSE 'WEB'
        END AS sales_type,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_quantity) AS avg_quantity,
        w.warehouse_name
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        ROLLUP(w.warehouse_name)
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    ci.buy_potential,
    sr.total_returned_quantity,
    sd.sales_type,
    sd.total_profit,
    sd.avg_quantity
FROM 
    CustomerIncome ci 
LEFT JOIN 
    RankedReturns sr ON ci.c_customer_sk = sr.s_returning_customer_sk AND sr.rnk = 1
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.sales_type
WHERE 
    (ci.cd_gender = 'F' OR ci.cd_marital_status IS NULL)
    AND ci.ib_lower_bound < 20000
    OR ci.buy_potential IS NOT NULL
    AND sd.total_profit > 5000
ORDER BY 
    ci.c_customer_sk ASC, 
    COALESCE(sd.total_profit, 0) DESC
LIMIT 100 OFFSET 10;
