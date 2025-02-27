
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateSummary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_quantity) AS total_items_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ds.d_year,
    ds.d_month_seq,
    ds.total_orders,
    ds.total_sales,
    ds.total_items_sold,
    p.promo_order_count,
    p.promo_sales
FROM 
    CustomerInfo ci
JOIN 
    DateSummary ds ON ci.c_customer_id IN (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws)
LEFT JOIN 
    Promotions p ON p.promo_order_count > 0
ORDER BY 
    ds.total_sales DESC, ci.full_name;
