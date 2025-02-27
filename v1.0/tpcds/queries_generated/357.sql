
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS highest_sale_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws.ws_net_paid) AS median_payment
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_purchase_estimate > 100
    GROUP BY 
        ws.web_site_id, ws.web_name
),
top_websites AS (
    SELECT 
        web_id,
        web_name,
        total_profit,
        total_orders,
        highest_sale_price,
        median_payment,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) as rank
    FROM 
        sales_data
)
SELECT 
    w.warehouse_name,
    tw.web_name,
    tw.total_profit,
    tw.total_orders,
    tw.highest_sale_price,
    tw.median_payment,
    COALESCE(c.t_number, 0) AS customer_count
FROM 
    warehouse w
LEFT JOIN 
    top_websites tw ON w.warehouse_sk = tw.web_id
LEFT JOIN 
    (SELECT 
        ws_bill_address_sk, COUNT(DISTINCT ws_bill_customer_sk) AS t_number
     FROM 
        web_sales
     GROUP BY 
        ws_bill_address_sk
    ) c ON tw.web_id = c.ws_bill_address_sk
WHERE 
    w.warehouse_sq_ft > 50000 OR 
    (SELECT COUNT(*) FROM store WHERE s_floor_space > 10000) > 10
ORDER BY 
    tw.total_profit DESC 
LIMIT 10;
