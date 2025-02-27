
WITH RECURSIVE RevenueCTE AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS revenue_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate
    FROM 
        CustomerInfo ci
    WHERE 
        ci.gender_rank <= 10
),
SalesSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
)
SELECT 
    r.web_site_sk,
    r.total_revenue,
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    s.i_item_id,
    s.total_sales,
    s.total_store_sales,
    s.total_catalog_sales,
    (s.total_sales + s.total_store_sales + s.total_catalog_sales) AS overall_total_sales,
    CASE 
        WHEN r.total_revenue > 100000 THEN 'High'
        WHEN r.total_revenue > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM 
    RevenueCTE r
JOIN 
    TopCustomers tc ON r.web_site_sk = tc.c_customer_sk 
JOIN 
    SalesSummary s ON tc.c_customer_sk = s.i_item_sk
WHERE 
    r.revenue_rank <= 5
ORDER BY 
    r.total_revenue DESC, 
    overall_total_sales DESC;
