
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        COUNT(*) AS return_count,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(*) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
HighReturnItems AS (
    SELECT 
        rr.sr_item_sk,
        i.i_item_desc,
        i.i_current_price,
        rr.return_count
    FROM 
        RankedReturns rr
    JOIN 
        item i ON rr.sr_item_sk = i.i_item_sk
    WHERE 
        rr.rank = 1 AND rr.return_count > 100
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(DISTINCT sr_ticket_number) AS unique_returns, 
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
EligibleCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.unique_returns,
        cr.total_return_amount,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cr.total_return_amount IS NOT NULL AND 
        cr.unique_returns > 5 AND 
        cd.cd_gender = 'F'
),
FinalReport AS (
    SELECT 
        e.c_customer_id,
        e.unique_returns,
        e.total_return_amount,
        SUM(CASE WHEN h.hd_income_band_sk IS NULL THEN 0 ELSE 1 END) AS valid_income_groups,
        CONCAT(e.c_customer_id, ' has ', e.unique_returns, ' returns totaling ', e.total_return_amount) AS report_text
    FROM 
        EligibleCustomers e
    LEFT JOIN 
        household_demographics h ON e.c_customer_id = CAST(h.hd_demo_sk AS CHAR)
    GROUP BY 
        e.c_customer_id, e.unique_returns, e.total_return_amount
)

SELECT 
    fr.c_customer_id,
    fr.unique_returns,
    fr.total_return_amount,
    fr.valid_income_groups,
    fr.report_text,
    (SELECT 
        MAX(ws_net_profit) 
     FROM 
        web_sales 
     WHERE 
        ws_item_sk IN (SELECT 
                            i.i_item_sk 
                        FROM 
                            HighReturnItems i)) AS max_web_profit
FROM 
    FinalReport fr
WHERE 
    fr.valid_income_groups > 2
ORDER BY 
    fr.total_return_amount DESC
LIMIT 20;
