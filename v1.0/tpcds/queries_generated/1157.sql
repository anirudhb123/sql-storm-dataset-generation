
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_spending,
        AVG(cd.cd_dep_count) AS avg_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
ReturnStats AS (
    SELECT 
        sr.store_sk,
        SUM(sr.return_quantity) AS total_returns,
        SUM(sr.return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr.customer_sk) AS customers_returned
    FROM 
        store_returns sr
    GROUP BY 
        sr.store_sk
),
SalesStats AS (
    SELECT 
        ws.ws_ship_mode_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_mode_sk
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    rs.total_returns,
    rs.total_return_amount,
    ss.total_sales,
    ss.total_orders,
    COALESCE(rs.total_returns, 0) AS total_returned_items,
    NULLIF(ss.total_sales, 0) AS net_sales,
    res.avg_dependents / NULLIF(cs.total_customers, 0) AS avg_dependents_per_customer
FROM 
    CustomerStats cs
LEFT JOIN 
    ReturnStats rs ON cs.total_customers > 0
LEFT JOIN 
    SalesStats ss ON ss.total_sales > 1000
ORDER BY 
    cs.cd_gender, cs.cd_marital_status;
