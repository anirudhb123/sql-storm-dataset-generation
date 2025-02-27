
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_dep_employed_count) AS total_dependent_employed
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    GROUP BY 
        d.d_year
),
ReturnStats AS (
    SELECT 
        cr_reason_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amt) AS total_return_value
    FROM 
        catalog_returns cr
    GROUP BY 
        cr_reason_sk
)
SELECT 
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.avg_dependents,
    cs.total_dependent_employed,
    ss.d_year,
    ss.total_sales,
    ss.total_orders,
    ss.avg_order_value,
    rs.total_returns,
    rs.total_return_value
FROM 
    CustomerStats cs
JOIN 
    SalesStats ss ON cs.customer_count > 1000
JOIN 
    ReturnStats rs ON rs.total_returns > 50
ORDER BY 
    ss.d_year DESC, cs.customer_count DESC;
