
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_return_number) AS return_count,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rnk
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependents,
        COALESCE(cd.cd_credit_rating, 'unknown') AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
TopReturnedItems AS (
    SELECT 
        rr.sr_item_sk
    FROM 
        store_returns sr 
    JOIN 
        RankedReturns rr ON sr.sr_item_sk = rr.sr_item_sk
    WHERE 
        rr.return_count > (
            SELECT AVG(return_count) FROM RankedReturns
        )
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.credit_rating,
    ti.sr_item_sk,
    ti.total_returned,
    ti.total_return_amount,
    CASE 
        WHEN ci.credit_rating = 'unknown' THEN 'Requires Update'
        ELSE 'Active'
    END AS status,
    CASE 
        WHEN ci.cd_gender = 'F' THEN 'Female'
        WHEN ci.cd_gender = 'M' THEN 'Male'
        ELSE 'Non-binary/Other'
    END AS gender_desc
FROM 
    CustomerInfo ci
JOIN 
    TopReturnedItems ti ON ci.c_customer_sk = ti.sr_item_sk
LEFT JOIN 
    LATERAL (
        SELECT 
            COUNT(ws_order_number) AS order_count
        FROM 
            web_sales
        WHERE 
            ws_ship_customer_sk = ci.c_customer_sk 
            AND ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    ) ws ON TRUE
ORDER BY 
    total_return_amount DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
