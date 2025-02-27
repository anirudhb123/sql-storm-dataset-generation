
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_return_quantity,
        wr_return_amt,
        wr_return_tax,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY wr_return_amt DESC) as rnk
    FROM 
        web_returns
    WHERE 
        wr_return_date_sk IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ws.total_sales,
    ws.order_count,
    COALESCE(rr.total_return_quantity, 0) as total_return_quantity,
    COALESCE(rr.total_return_amt, 0) as total_return_amt
FROM 
    CustomerDemographics cd
LEFT JOIN WebSalesSummary ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) as total_return_quantity,
        SUM(wr_return_amt) as total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
) rr ON cd.c_customer_sk = rr.wr_returning_customer_sk
WHERE 
    cd.cd_purchase_estimate > 500
ORDER BY 
    total_sales DESC
LIMIT 100;
