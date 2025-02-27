
WITH RECURSIVE revenue_analysis AS (
    SELECT 
        ci.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS revenue_rank
    FROM 
        customer ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk
), customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        AVG(cd.cd_dep_count) AS avg_dep_count
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk
), address_info AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk
), sales_summary AS (
    SELECT 
        s.ss_store_sk,
        SUM(s.ss_ext_sales_price) AS total_sales,
        COUNT(s.ss_ticket_number) AS transaction_count,
        (SUM(s.ss_ext_sales_price) / NULLIF(SUM(s.ss_quantity), 0)) AS avg_price_per_item
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        s.ss_store_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COALESCE(ra.total_revenue, 0) AS total_revenue,
    COALESCE(da.max_purchase_estimate, 0) AS max_estimated_purchase,
    sa.total_sales,
    sa.transaction_count,
    sa.avg_price_per_item
FROM 
    customer_address ca
LEFT JOIN 
    revenue_analysis ra ON ra.c_customer_sk IN (
        SELECT DISTINCT c.c_customer_sk
        FROM customer c
        WHERE c.c_current_addr_sk = ca.ca_address_sk
    )
LEFT JOIN 
    customer_demographics da ON da.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk LIMIT 1)
LEFT JOIN 
    sales_summary sa ON sa.ss_store_sk IN (
        SELECT DISTINCT s.s_store_sk
        FROM store s
        WHERE s.s_zip = ca.ca_zip
    )
WHERE 
    ca.ca_country ILIKE 'United States' 
    AND ra.revenue_rank <= 100
ORDER BY 
    total_revenue DESC, 
    total_sales DESC
LIMIT 50;
