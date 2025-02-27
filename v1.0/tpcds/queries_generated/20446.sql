
WITH RankedReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(*) AS total_returns,
        RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rnk
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT
        r.cr_returning_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cr_return_amt) AS total_refunded
    FROM
        RankedReturns r
        JOIN customer c ON r.cr_returning_customer_sk = c.c_customer_sk
    WHERE
        r.rnk <= 10
    GROUP BY
        r.cr_returning_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating 
        END AS credit_rating,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 0
            ELSE cd.cd_dep_count 
        END AS dependent_count
    FROM
        customer_demographics cd
)
SELECT
    t.rc.customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_refunded,
    cd.gender,
    cd.marital_status,
    cd.purchase_estimate,
    cd.credit_rating,
    cd.dependent_count,
    COALESCE(ct.total_account_credits, 0) AS total_account_credits,
    sm.sm_type AS preferred_ship_mode,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) > 1000 THEN 'Premium'
        WHEN SUM(ws.ws_ext_sales_price) BETWEEN 500 AND 1000 THEN 'Standard'
        ELSE 'Basic'
    END AS customer_category
FROM
    TopReturningCustomers t
    JOIN CustomerDemographics cd ON t.cr_returning_customer_sk = cd.cd_demo_sk
    LEFT JOIN (SELECT
                   ws_bill_customer_sk,
                   COUNT(DISTINCT ws_order_number) AS total_account_credits
               FROM
                   web_sales
               GROUP BY
                   ws_bill_customer_sk) ct ON t.cr_returning_customer_sk = ct.ws_bill_customer_sk
    LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk IN (
        SELECT sm_ship_mode_sk FROM web_sales WHERE ws_bill_customer_sk = t.cr_returning_customer_sk
    )
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = t.cr_returning_customer_sk
GROUP BY
    t.rc.customer_sk,
    t.c_first_name,
    t.c_last_name,
    cd.gender,
    cd.marital_status,
    cd.purchase_estimate,
    cd.credit_rating,
    cd.dependent_count,
    ct.total_account_credits,
    sm.sm_type
HAVING
    SUM(ws.ws_ext_sales_price) > 200
ORDER BY
    total_refunded DESC,
    total_spent ASC;
