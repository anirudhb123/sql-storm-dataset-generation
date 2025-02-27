
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales_price,
        AVG(ws.ws_sales_price) AS average_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_item_sk
), 
customer_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
        COUNT(DISTINCT c.c_customer_id) FILTER (WHERE cd.cd_gender = 'M') AS male_customers,
        COUNT(DISTINCT c.c_customer_id) FILTER (WHERE cd.cd_gender = 'F') AS female_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 1000
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ss.ws_item_sk,
    ss.total_quantity,
    ss.total_sales_price,
    ss.average_sales_price,
    cs.total_customers,
    cs.average_purchase_estimate,
    cs.male_customers,
    cs.female_customers
FROM 
    sales_summary ss
LEFT JOIN 
    customer_summary cs ON ss.ws_item_sk IN (SELECT DISTINCT cs_item_sk FROM catalog_sales WHERE cs_sold_date_sk = (
        SELECT MAX(cs_sold_date_sk) FROM catalog_sales))
ORDER BY 
    total_sales_price DESC
LIMIT 100;
