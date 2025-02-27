
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_count) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
SalesStats AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_coupon_amt) AS total_coupons
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
),
ReturnsStats AS (
    SELECT 
        cr_returned_date_sk,
        COUNT(cr_order_number) AS total_returns,
        SUM(cr_return_amt) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returned_date_sk
),
FinalStats AS (
    SELECT 
        ds.d_date AS sales_date,
        cs.total_customers,
        cs.avg_purchase_estimate,
        ss.total_sales,
        ss.total_profit,
        rs.total_returns,
        rs.total_return_amount
    FROM 
        date_dim ds
    LEFT JOIN 
        CustomerStats cs ON ds.d_date_sk = cs.cd_gender
    LEFT JOIN 
        SalesStats ss ON ds.d_date_sk = ss.ws_ship_date_sk
    LEFT JOIN 
        ReturnsStats rs ON ds.d_date_sk = rs.cr_returned_date_sk
)
SELECT 
    sales_date,
    total_customers,
    avg_purchase_estimate,
    total_sales,
    total_profit,
    total_returns,
    total_return_amount
FROM 
    FinalStats
ORDER BY 
    sales_date DESC
LIMIT 100;
