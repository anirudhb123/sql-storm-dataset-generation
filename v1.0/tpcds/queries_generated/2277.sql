
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_addr_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_addr_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk
), 
SalesInfo AS (
    SELECT 
        wm.wm_web_site_id,
        wm.web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM 
        web_sales ws
    JOIN 
        web_site wm ON ws.ws_web_site_sk = wm.web_site_sk
    GROUP BY 
        wm.wm_web_site_id, wm.web_site_sk
)
SELECT 
    c.gender,
    c.marital_status,
    c.income_band_sk,
    s.order_count,
    s.total_sales,
    s.avg_discount,
    RANK() OVER (PARTITION BY c.gender, c.marital_status ORDER BY s.total_sales DESC) AS sales_rank
FROM 
    CustomerInfo c
JOIN 
    SalesInfo s ON c.total_orders > 0 
WHERE 
    (c.income_band_sk >= 1 OR c.income_band_sk = -1)
    AND c.total_spent > 1000
ORDER BY 
    c.gender, c.marital_status, s.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
