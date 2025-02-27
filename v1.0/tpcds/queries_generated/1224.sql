
WITH CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ReturnMetrics AS (
    SELECT 
        d.d_date,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cr.return_count) AS total_returns,
        SUM(cr.total_returned_quantity) AS total_returned_quantity,
        SUM(cr.total_returned_amount) AS total_returned_amount
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.sr_returning_customer_sk = cd.c_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns sr WHERE sr.returning_customer_sk = cd.c_customer_sk)
    GROUP BY 
        d.d_date, cd.cd_gender, cd.cd_marital_status
),
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id, sm.sm_carrier
),
FinalMetrics AS (
    SELECT 
        rm.d_date,
        rm.cd_gender,
        rm.cd_marital_status,
        COALESCE(sm.order_count, 0) AS online_order_count,
        COALESCE(sm.total_sales, 0) AS online_total_sales,
        rm.total_returns,
        rm.total_returned_quantity,
        rm.total_returned_amount
    FROM 
        ReturnMetrics rm
    LEFT JOIN 
        ShippingModes sm ON rm.d_date = CURRENT_DATE
)
SELECT 
    f.d_date,
    f.cd_gender,
    f.cd_marital_status,
    f.online_order_count,
    f.online_total_sales,
    f.total_returns,
    f.total_returned_quantity,
    f.total_returned_amount,
    CASE 
        WHEN f.total_returns > 0 THEN ROUND((f.total_returned_amount / NULLIF(f.total_returns, 0)), 2)
        ELSE 0
    END AS avg_return_amt_per_return,
    CASE 
        WHEN f.online_total_sales > 0 THEN ROUND((f.total_returns / NULLIF(f.online_order_count, 0)), 2)
        ELSE 0
    END AS return_rate_to_sales_ratio
FROM 
    FinalMetrics f
ORDER BY 
    f.d_date DESC, f.cd_gender, f.cd_marital_status;
