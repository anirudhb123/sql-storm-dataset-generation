
WITH RECURSIVE CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(wr_order_number) AS total_orders
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
    UNION ALL
    SELECT
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amount) AS total_return_amount,
        COUNT(sr_order_number) AS total_orders
    FROM
        store_returns
    GROUP BY
        sr_returning_customer_sk
),
AggregateReturns AS (
    SELECT
        cr.wr_returning_customer_sk AS customer_sk,
        COALESCE(SUM(cr.total_returned), 0) AS total_returned,
        COALESCE(SUM(cr.total_return_amount), 0) AS total_return_amount,
        COUNT(DISTINCT cr.total_orders) AS total_orders
    FROM
        CustomerReturns cr
    GROUP BY
        cr.wr_returning_customer_sk
),
TopDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ar.total_return_amount) DESC) AS rnk
    FROM
        AggregateReturns ar
    JOIN
        customer c ON ar.customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state
)
SELECT
    td.cd_gender,
    td.ca_city,
    td.cd_marital_status,
    AVG(td.total_returned) AS avg_returned,
    SUM(td.total_return_amount) AS total_return_amount,
    CASE
        WHEN AVG(td.total_returned) > 10 THEN 'High'
        WHEN AVG(td.total_returned) BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS return_status
FROM 
    AggregateReturns ar
JOIN
    TopDemographics td ON ar.customer_sk = td.cd_demo_sk
GROUP BY
    td.cd_gender, td.ca_city, td.cd_marital_status
HAVING 
    SUM(td.total_return_amount) > 1000
ORDER BY 
    return_status DESC, avg_returned DESC
LIMIT 50;
