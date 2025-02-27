
WITH RecursiveCustomerReturns AS (
    SELECT 
        cr.returning_customer_sk, 
        SUM(cr.return_quantity) AS total_returned_items,
        COUNT(cr.returning_customer_sk) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY cr.returning_customer_sk ORDER BY SUM(cr.return_quantity) DESC) AS rn
    FROM 
        catalog_returns cr
    WHERE 
        cr.returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '1 day')
    GROUP BY 
        cr.returning_customer_sk
),
CustomerReturnDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_returned_items,
        r.return_count
    FROM 
        customer c
    JOIN 
        RecursiveCustomerReturns r ON c.c_customer_sk = r.returning_customer_sk
    WHERE 
        r.rn = 1
),
TopIncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        income_band ib
    JOIN 
        household_demographics hd ON ib.ib_lower_bound <= hd.hd_income_band_sk 
        AND ib.ib_upper_bound >= hd.hd_income_band_sk
    JOIN 
        customer c ON c.c_customer_sk = hd.hd_demo_sk
    GROUP BY 
        ib.ib_income_band_sk
    ORDER BY 
        customer_count DESC
    LIMIT 1
),
HighReturnCustomers AS (
    SELECT 
        DISTINCT cd.demo_sk,
        cd.cd_gender, 
        cd.cd_marital_status,
        r.total_returned_items,
        r.return_count
    FROM 
        RecursiveCustomerReturns r
    JOIN 
        customer_demographics cd ON r.returning_customer_sk = cd.cd_demo_sk
    WHERE 
        r.total_returned_items > (SELECT AVG(total_returned_items) FROM RecursiveCustomerReturns)
)
SELECT 
    ccd.c_customer_id,
    ccd.c_first_name,
    ccd.c_last_name,
    ccd.total_returned_items,
    ib.ib_income_band_sk,
    CASE 
        WHEN ccd.total_returned_items IS NULL THEN 'No Returns'
        ELSE 'Returned Items: ' || ccd.total_returned_items::text
    END AS return_status,
    cd.cd_gender
FROM 
    CustomerReturnDetails ccd
LEFT JOIN 
    TopIncomeBand ib ON 1=1
JOIN 
    HighReturnCustomers hdrc ON ccd.c_customer_id = hdrc.demo_sk
WHERE 
    hdrc.cd_gender IS NOT NULL 
    AND (hdrc.return_count > 5 OR hdrc.cd_marital_status = 'S')
ORDER BY 
    ccd.total_returned_items DESC,
    ccd.c_last_name,
    ccd.c_first_name
LIMIT 10;
