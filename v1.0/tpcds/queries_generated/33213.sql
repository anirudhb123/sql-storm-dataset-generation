
WITH RECURSIVE SalesGrowth AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year BETWEEN 2015 AND 2020
    GROUP BY 
        d_year
    UNION ALL
    SELECT 
        sg.d_year + 1,
        SUM(ws_ext_sales_price),
        SUM(ws_net_profit)
    FROM 
        SalesGrowth sg
    JOIN 
        web_sales ws ON ws.ws_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_year = sg.d_year + 1)
    GROUP BY 
        sg.d_year
),
CustomerStats AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_sk) AS customer_count, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
ShipModeStats AS (
    SELECT 
        sm.sm_type,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        web_sales 
    JOIN 
        ship_mode sm ON sm.sm_ship_mode_sk = ws_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    sg.d_year,
    sg.total_sales,
    sg.total_profit,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    sms.sm_type,
    sms.order_count,
    sms.avg_net_paid
FROM 
    SalesGrowth sg
CROSS JOIN 
    CustomerStats cs
CROSS JOIN 
    ShipModeStats sms
WHERE 
    sg.total_sales IS NOT NULL 
    AND (cs.customer_count > 0 OR sms.order_count > 0)
ORDER BY 
    sg.d_year DESC, 
    cs.customer_count DESC;
