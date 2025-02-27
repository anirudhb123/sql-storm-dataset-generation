
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
), 
PromotionalSales AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_net_paid) AS promo_sales
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id
)

SELECT 
    s.web_site_id,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_net_profit,
    cd.customer_count,
    cd.avg_purchase_estimate,
    ps.promo_sales
FROM 
    SalesSummary ss
LEFT JOIN 
    CustomerDemographics cd ON ss.total_quantity > 100
LEFT JOIN 
    PromotionalSales ps ON ss.total_sales > 1000
WHERE 
    ss.sales_rank = 1
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
