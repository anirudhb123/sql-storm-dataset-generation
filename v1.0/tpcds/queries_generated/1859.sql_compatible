
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
), customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(ws.ws_item_sk) AS item_count,
        CASE 
            WHEN SUM(ws.ws_sales_price) IS NULL THEN 'No Sales'
            WHEN SUM(ws.ws_sales_price) < 100 THEN 'Low Spending'
            WHEN SUM(ws.ws_sales_price) BETWEEN 100 AND 500 THEN 'Moderate Spending'
            ELSE 'High Spending'
        END AS spending_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
), product_performance AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_sales_price) AS total_sales_price,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
)
SELECT 
    r.web_site_sk,
    cs.c_customer_sk,
    cs.cd_gender,
    cs.total_spent,
    pp.total_sales_price,
    pp.avg_net_profit,
    pp.total_orders
FROM 
    ranked_sales r
LEFT JOIN 
    customer_summary cs ON r.web_site_sk = cs.c_customer_sk
LEFT JOIN 
    product_performance pp ON pp.total_sales_price > 100
WHERE 
    cs.spending_category = 'High Spending' 
    AND r.rank <= 5
ORDER BY 
    r.total_sales DESC, cs.total_spent DESC;
