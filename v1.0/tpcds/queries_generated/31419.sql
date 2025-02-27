
WITH RECURSIVE revenue_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
high_income_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating = 'High'
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        IFNULL(cr.cr_return_quantity, 0) AS return_quantity,
        (ws.ws_net_paid - IFNULL(cr.cr_return_amt, 0)) AS net_paid_final
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
    LEFT JOIN 
        catalog_returns cr ON ws.ws_item_sk = cr.cr_item_sk AND ws.ws_order_number = cr.cr_order_number
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    COALESCE(SUM(sd.net_paid_final), 0) AS total_net_sales,
    COUNT(DISTINCT h.ic_customer_sk) AS high_income_customer_count,
    AVG(r.total_revenue) AS avg_revenue
FROM 
    sales_data sd
LEFT JOIN 
    store s ON sd.ws_item_sk = s.s_store_sk
LEFT JOIN 
    high_income_customers h ON sd.ws_bill_customer_sk = h.c_customer_sk
LEFT JOIN 
    revenue_cte r ON sd.ws_item_sk = r.ws_item_sk
GROUP BY 
    s.s_store_id, s.s_store_name
HAVING 
    total_net_sales > 1000
ORDER BY 
    avg_revenue DESC;
