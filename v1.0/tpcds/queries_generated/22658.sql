
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk AS customer_sk, 
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
    HAVING 
        SUM(sr_return_quantity) > 0
),
RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        COALESCE(cd_dep_count, 0) AS dependent_count,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_description
    FROM 
        customer_demographics
),
AggregatedReturns AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        COALESCE(cr.total_returns, 0) AS return_count 
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ar.c_customer_id,
    ar.ca_city,
    ar.ca_state,
    ar.return_count,
    rd.ws_customer_sk,
    rd.total_profit,
    CASE 
        WHEN ar.return_count > 5 THEN 'High Return'
        WHEN ar.return_count BETWEEN 1 AND 5 THEN 'Moderate Return'
        ELSE 'No Returns'
    END AS return_category,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM RankedSales r 
            WHERE r.ws_bill_customer_sk = ar.c_customer_id AND r.profit_rank = 1
        ) THEN 'Top Profitable Customer'
        ELSE 'Regular Customer'
    END AS customer_type 
FROM 
    AggregatedReturns ar
LEFT JOIN 
    RankedSales rd ON ar.c_customer_id = rd.ws_bill_customer_sk 
WHERE 
    (ar.return_count IS NOT NULL OR rd.total_profit IS NOT NULL)
    AND ar.ca_state IN ('CA', 'TX', 'NY')
ORDER BY 
    ar.return_count DESC, 
    rd.total_profit DESC NULLS LAST;
