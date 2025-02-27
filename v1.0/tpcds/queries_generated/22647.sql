
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(cd.cd_demo_sk) AS demographic_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        cd.cd_gender
),
Returns AS (
    SELECT 
        sr.returned_date_sk,
        SUM(sr.return_quantity) AS total_returns,
        COUNT(*) AS return_count
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date_sk IS NOT NULL
    GROUP BY 
        sr.returned_date_sk
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    rd.d_date_id,
    cs.c_customer_id,
    cd.cd_gender,
    SUM(ws.ws_net_paid) AS daily_sales,
    COALESCE(rt.total_returns, 0) AS daily_returns,
    COALESCE(pr.promo_sales_count, 0) AS promo_sales_count,
    CASE 
        WHEN SUM(ws.ws_net_paid) IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    date_dim rd
LEFT JOIN 
    web_sales ws ON rd.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN 
    RankedSales rs ON rs.c_customer_id = ws.ws_bill_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_marital_status = 'M'
LEFT JOIN 
    Returns rt ON rt.returned_date_sk = rd.d_date_sk
LEFT JOIN 
    Promotions pr ON pr.p_promo_id IS NOT NULL
WHERE 
    rd.d_year = 2023 AND (ws.ws_net_paid IS NULL OR ws.ws_net_paid > 100) 
GROUP BY 
    rd.d_date_id, cs.c_customer_id, cd.cd_gender, rt.total_returns, pr.promo_sales_count
ORDER BY 
    rd.d_date_id, daily_sales DESC;
