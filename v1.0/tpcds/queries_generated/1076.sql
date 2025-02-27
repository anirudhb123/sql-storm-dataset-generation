
WITH CustomerReturns AS (
    SELECT 
        cr_returned_date_sk,
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returned_date_sk,
        cr_returning_customer_sk
),
WebSalesAnalysis AS (
    SELECT 
        ws_ship_date_sk,
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_ship_date_sk, 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_income_band_sk
    FROM 
        customer_demographics
    WHERE 
        cd_credit_rating IS NOT NULL
),
ReturnToSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(cr.total_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(ws.total_sales), 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        WebSalesAnalysis ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_income_band_sk,
    rts.total_return_quantity,
    rts.total_sales,
    CASE 
        WHEN rts.total_sales > 0 THEN (rts.total_return_quantity::decimal / rts.total_sales) * 100
        ELSE 0 
    END AS return_percentage
FROM 
    ReturnToSales rts
JOIN 
    customer c ON rts.c_customer_id = c.c_customer_id
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    return_percentage DESC
LIMIT 100;
