
WITH CTE_CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), CTE_Returns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
), CTE_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    d.avg_purchase_estimate
FROM 
    CTE_CustomerSales cs
LEFT JOIN 
    CTE_Returns r ON cs.c_customer_sk = r.sr_returning_customer_sk
JOIN 
    CTE_Demographics d ON cs.c_customer_sk = d.cd_demo_sk
WHERE 
    cs.total_sales > 1000
    OR d.avg_purchase_estimate IS NOT NULL
ORDER BY 
    total_sales DESC, total_returns ASC
LIMIT 50;
