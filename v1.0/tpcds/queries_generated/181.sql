
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
TopReturns AS (
    SELECT
        rt.returning_customer_sk,
        rt.total_return_quantity,
        rt.total_return_amt_inc_tax,
        COALESCE(cd.cd_gender, 'Unknown') AS customer_gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        RankedReturns rt
    LEFT JOIN 
        customer c ON rt.returning_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        rt.rank <= 10
    GROUP BY 
        rt.returning_customer_sk, rt.total_return_quantity, rt.total_return_amt_inc_tax, cd.cd_gender, cd.cd_marital_status
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_address_sk) AS addr_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    tr.returning_customer_sk,
    tr.total_return_quantity,
    tr.total_return_amt_inc_tax,
    tr.customer_gender,
    tr.marital_status,
    ca.ca_city,
    ca.ca_state,
    tr.orders_count
FROM 
    TopReturns tr
LEFT JOIN 
    CustomerAddresses ca ON tr.returning_customer_sk = ca.c_customer_sk AND ca.addr_rank = 1
WHERE 
    tr.total_return_amt_inc_tax > 100 
    AND tr.total_return_quantity IS NOT NULL
ORDER BY 
    tr.total_return_amt_inc_tax DESC, 
    tr.total_return_quantity DESC
LIMIT 25;
