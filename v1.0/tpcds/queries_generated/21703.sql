
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        (SELECT COUNT(*) 
         FROM store s 
         WHERE s.s_state IN ('CA', 'NY') 
           AND s.s_number_employees IS NOT NULL) AS active_stores
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(rr.sr_return_quantity) AS total_returned_quantity,
    AVG(rr.sr_return_amt) AS avg_return_amount,
    CASE 
        WHEN COUNT(rr.sr_return_quantity) IS NULL THEN 'No Returns'
        ELSE 'Returns Exist'
    END AS return_status,
    MAX(cd.active_stores) AS num_active_stores,
    COALESCE(cd.hd_buy_potential, 'Unknown') AS buying_potential,
    LEAD(SUM(rr.sr_return_quantity)) OVER (PARTITION BY cd.c_customer_sk ORDER BY MAX(rr.sr_return_amt) DESC) AS next_return_quantity
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedReturns rr ON cd.c_customer_sk = rr.sr_returning_customer_sk
GROUP BY 
    cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.hd_buy_potential
HAVING 
    SUM(rr.sr_return_quantity) > 0 OR MAX(rr.sr_return_amt) IS NOT NULL
ORDER BY 
    total_returned_quantity DESC
LIMIT 10;
