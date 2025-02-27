
WITH CustomerReturns AS (
    SELECT 
        COALESCE(cr.returning_customer_sk, wr.returning_customer_sk) AS customer_sk,
        SUM(COALESCE(cr.return_quantity, 0) + COALESCE(wr.return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT COALESCE(cr.order_number, wr.order_number)) AS return_count,
        COUNT(DISTINCT COALESCE(cr.item_sk, wr.item_sk)) AS unique_items_returned
    FROM 
        catalog_returns cr
    FULL OUTER JOIN 
        web_returns wr ON cr.returning_customer_sk = wr.returning_customer_sk
    GROUP BY 
        COALESCE(cr.returning_customer_sk, wr.returning_customer_sk)
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year, c.c_birth_month DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ActiveCustomers AS (
    SELECT 
        d.d_date, 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.gender,
        cr.total_returns,
        cr.return_count,
        cr.unique_items_returned
    FROM 
        date_dim d
    JOIN 
        CustomerDemographics c ON c.rn = 1
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.customer_sk
    WHERE 
        d.d_date = CURRENT_DATE
)
SELECT 
    ac.c_customer_sk,
    ac.c_first_name,
    ac.c_last_name,
    COALESCE(ac.total_returns, 0) AS total_returns,
    CASE 
        WHEN ac.return_count IS NULL THEN 'No Returns'
        WHEN ac.return_count > 5 THEN 'Frequent Returner'
        ELSE 'Occasional Returner'
    END AS return_status,
    ac.gender,
    SUM(i.i_current_price) AS total_spent
FROM 
    ActiveCustomers ac
LEFT JOIN 
    web_sales ws ON ac.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk 
GROUP BY 
    ac.c_customer_sk, ac.c_first_name, ac.c_last_name, ac.total_returns, ac.return_count, ac.gender
HAVING 
    total_spent > (SELECT AVG(i_current_price) FROM item) 
    OR ac.total_returns > 0 
ORDER BY 
    total_spent DESC NULLS LAST;
