
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
    HAVING 
        SUM(sr_return_amt_inc_tax) > 100
    UNION ALL
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amt_inc_tax) AS total_return_amt
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
    HAVING 
        SUM(cr_return_amt_inc_tax) > 100
),
RankedDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        RANK() OVER (PARTITION BY cd_gender ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
ReturnStats AS (
    SELECT
        cr.returning_customer_sk AS customer_sk,
        SUM(cr.return_amt_inc_tax) AS total_cr_return_amt,
        COUNT(cr.return_quantity) AS cr_return_count,
        SUM(cr_return_ship_cost) AS cr_total_ship_cost
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
)

SELECT 
    ca.city,
    ca.state,
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    COALESCE(SUM(rs.total_cr_return_amt), 0) AS total_catalog_return,
    COALESCE(SUM(crs.total_return_amt), 0) AS total_store_return,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    COUNT(DISTINCT wd.warehouse_sk) AS total_warehouses,
    RANK() OVER (ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS customer_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    RankedDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    (SELECT * FROM CustomerReturns) crs ON c.c_customer_sk = crs.returning_customer_sk
LEFT JOIN 
    (SELECT * FROM ReturnStats) rs ON c.c_customer_sk = rs.customer_sk
JOIN 
    warehouse wd ON wd.w_warehouse_sk IN (SELECT DISTINCT inv_warehouse_sk FROM inventory)
WHERE 
    ca.state IS NOT NULL
GROUP BY 
    ca.city, ca.state, cd.cd_gender
ORDER BY 
    total_customers DESC, ca.city;
