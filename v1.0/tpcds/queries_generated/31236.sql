
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
    UNION ALL
    SELECT 
        sr_returning_customer_sk AS customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(cr.total_return_value, 0) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_returns,
    cs.total_return_value,
    cs.cd_gender,
    cs.cd_marital_status
FROM 
    CustomerStats cs
WHERE 
    cs.gender_rank <= 5
    AND (cs.cd_marital_status = 'M' OR cs.cd_marital_status = 'S')
ORDER BY 
    cs.total_return_value DESC;

-- Perform a performance benchmark against possible indexing scenarios
CREATE INDEX idx_customer_gender ON customer_demographics(cd_gender);
CREATE INDEX idx_customer_returns ON web_returns(wr_returning_customer_sk);
CREATE INDEX idx_store_returns ON store_returns(sr_returning_customer_sk);
