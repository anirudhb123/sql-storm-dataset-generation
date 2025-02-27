
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
        AND ws.ws_sales_price > 0
),
TotalSales AS (
    SELECT 
        web_site_sk,
        SUM(ws_sales_price) AS total_revenue,
        COUNT(ws_order_number) AS total_orders
    FROM 
        RankedSales
    GROUP BY 
        web_site_sk
),
HighRevenueWebsites AS (
    SELECT 
        w.web_site_id,
        ts.total_revenue,
        ts.total_orders,
        CASE 
            WHEN ts.total_revenue IS NULL THEN 'No Revenue'
            ELSE 'Revenue Generated'
        END AS revenue_status
    FROM 
        web_site w
    LEFT JOIN 
        TotalSales ts ON w.web_site_sk = ts.web_site_sk
    WHERE 
        (ts.total_revenue > 10000 OR ts.total_revenue IS NULL)
        AND w.web_open_date_sk IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_gender IN ('M', 'F')
        AND cd.cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT 
        CASE 
            WHEN ws.ws_net_profit < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_loss,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        COALESCE(ws.ws_net_paid, 0) AS net_paid,
        cd.cd_gender
    FROM 
        web_sales ws
    LEFT JOIN 
        CustomerDemographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
)
SELECT 
    hw.web_site_id,
    hw.total_revenue,
    hw.total_orders,
    sd.profit_loss,
    sd.cd_gender,
    COUNT(sd.ws_quantity) AS total_sales_count,
    AVG(sd.net_paid) AS average_net_paid
FROM 
    HighRevenueWebsites hw
LEFT JOIN 
    SalesData sd ON hw.web_site_id IS NOT NULL
GROUP BY 
    hw.web_site_id, hw.total_revenue, hw.total_orders, sd.profit_loss, sd.cd_gender
HAVING 
    COUNT(sd.ws_quantity) > 0
ORDER BY 
    hw.total_revenue DESC, sd.cd_gender;
