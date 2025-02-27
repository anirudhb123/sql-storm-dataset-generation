
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
), 
HighIncomeCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        (ib.ib_upper_bound - ib.ib_lower_bound) AS income_range
    FROM 
        RankedCustomers AS rc 
    JOIN 
        household_demographics AS hd ON rc.c_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        rc.rn = 1
        AND (ib.ib_upper_bound > 100000 OR ib.ib_lower_bound IS NULL)
), 
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_returned_amount
    FROM 
        store_returns AS sr 
    GROUP BY 
        sr.sr_customer_sk
), 
ReturnAnalysis AS (
    SELECT 
        hic.c_customer_id,
        hic.cd_gender,
        hic.cd_marital_status,
        ri.total_returns,
        ri.total_returned_amount,
        CASE 
            WHEN ri.total_returns IS NULL THEN 'NO RETURNS'
            WHEN ri.total_returned_amount > 500 THEN 'HIGH RETURN'
            ELSE 'NORMAL RETURN'
        END AS return_category
    FROM 
        HighIncomeCustomers AS hic
    LEFT JOIN 
        CustomerReturns AS ri ON hic.c_customer_sk = ri.sr_customer_sk
), 
WebSalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sales_price > 50
    GROUP BY 
        ws.ws_bill_customer_sk
)

SELECT 
    ra.c_customer_id,
    ra.cd_gender,
    ra.cd_marital_status,
    ra.total_returns,
    ra.total_returned_amount,
    ra.return_category,
    wd.total_net_profit,
    wd.total_orders
FROM 
    ReturnAnalysis AS ra
LEFT JOIN 
    WebSalesData AS wd ON ra.c_customer_id = wd.ws_bill_customer_sk
WHERE 
    (ra.total_returns IS NOT NULL OR wd.total_net_profit IS NOT NULL)
    AND (ra.cd_gender = 'M' OR ra.cd_marital_status = 'S')
ORDER BY 
    ra.total_returned_amount DESC, 
    wd.total_net_profit DESC
LIMIT 100;
