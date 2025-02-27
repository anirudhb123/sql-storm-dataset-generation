
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_income_band_sk
),
PromotionDetails AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS total_promoted_sales
    FROM 
        promotion AS p
    JOIN 
        catalog_sales AS cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.order_count,
    rs.total_sales,
    pd.total_promoted_sales
FROM 
    CustomerInfo AS cs
JOIN 
    RankedSales AS rs ON cs.order_count > 0
JOIN 
    PromotionDetails AS pd ON pd.total_promoted_sales > 0
WHERE 
    cs.cd_income_band_sk IN (1, 2)
ORDER BY 
    rs.total_sales DESC, cs.c_last_name;
