
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_purchase_estimate > 1000
    GROUP BY 
        ws.web_site_id
),
top_sales AS (
    SELECT 
        web_site_id, 
        order_count, 
        total_sales
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.web_site_id, 
    t.order_count, 
    t.total_sales, 
    ca.ca_city, 
    ca.ca_state,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM 
    top_sales t
LEFT JOIN 
    web_site w ON t.web_site_id = w.web_site_id
LEFT JOIN 
    store_returns sr ON sr.sr_store_sk = w.w_warehouse_sk
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = sr.sr_customer_sk)
GROUP BY 
    t.web_site_id, 
    t.order_count, 
    t.total_sales, 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    total_sales DESC;
