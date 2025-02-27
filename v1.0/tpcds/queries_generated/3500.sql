
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_returned_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank
    FROM 
        store_returns
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_paid,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
ReturnSummary AS (
    SELECT 
        rr.sr_customer_sk,
        SUM(rr.sr_return_quantity) AS total_returned,
        SUM(rr.sr_return_amt) AS total_return_value
    FROM 
        RankedReturns rr
    WHERE 
        rr.return_rank <= 5
    GROUP BY 
        rr.sr_customer_sk
)
SELECT 
    cd.c_customer_sk,
    CONCAT(cd.c_first_name, ' ', cd.c_last_name) AS full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ss.total_paid,
    rs.total_returned,
    rs.total_return_value,
    CASE 
        WHEN rs.total_returned IS NULL THEN 'No Returns'
        WHEN rs.total_returned > 0 THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_status
FROM 
    CustomerData cd
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    ReturnSummary rs ON cd.c_customer_sk = rs.sr_customer_sk
WHERE 
    cd.cd_income_band_sk IS NOT NULL
    AND (
        ss.total_paid > 1000 OR rs.total_returned > 0
    )
ORDER BY 
    cd.c_customer_sk;
