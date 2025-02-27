
WITH TotalSales AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year >= 1970
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
PromotionDetails AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_ext_sales_price) AS total_promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    ts.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.total_spent,
    pd.promo_order_count,
    pd.total_promo_sales
FROM 
    TotalSales ts
LEFT JOIN 
    CustomerDetails cd ON ts.total_sales > 1000
LEFT JOIN 
    PromotionDetails pd ON pd.total_promo_sales > 500
ORDER BY 
    ts.total_sales DESC, cd.total_spent DESC;
