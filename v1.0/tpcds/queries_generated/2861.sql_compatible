
WITH RankedReturns AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY COUNT(*) DESC) AS return_rank
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
HighReturnCustomers AS (
    SELECT
        wr_returning_customer_sk,
        total_returns,
        total_return_amount
    FROM
        RankedReturns
    WHERE
        return_rank <= 10
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(ad.ca_city, 'Unknown') AS customer_city
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
)
SELECT
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_preferred_cust_flag,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    hrc.total_returns,
    hrc.total_return_amount,
    CASE
        WHEN hrc.total_return_amount > 1000 THEN 'High Risk'
        ELSE 'Low Risk'
    END AS return_risk,
    CASE
        WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'M' THEN 'Married Male'
        WHEN cd.cd_gender = 'M' THEN 'Single Male'
        WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' THEN 'Married Female'
        ELSE 'Single Female'
    END AS customer_category
FROM
    CustomerDetails cd
JOIN HighReturnCustomers hrc ON cd.c_customer_id = hrc.wr_returning_customer_sk
ORDER BY
    hrc.total_return_amount DESC;
