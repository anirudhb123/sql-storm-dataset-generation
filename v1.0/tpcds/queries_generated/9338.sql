
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit 
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        d.d_year = 2023
        AND ws.ws_net_paid > 0
    GROUP BY 
        ws.web_site_id, d.d_month_seq
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
), Promotions AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    sd.web_site_id,
    sd.d_month_seq,
    sd.total_sales,
    cd.customer_count,
    p.total_discount
FROM 
    SalesData sd 
LEFT JOIN 
    CustomerDemographics cd ON sd.web_site_id IN (SELECT w.web_site_id FROM web_site w)
LEFT JOIN 
    Promotions p ON p.total_discount > 1000
ORDER BY 
    sd.total_sales DESC, cd.customer_count DESC;
