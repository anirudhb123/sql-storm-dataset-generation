
WITH RECURSIVE sales_totals AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
high_sales AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        s.total_quantity,
        s.total_sales
    FROM 
        item i
    JOIN 
        sales_totals s ON i.i_item_sk = s.ws_item_sk
    WHERE 
        s.rn <= 10
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cd.cd_gender, 'U') AS gender,
        cd.cd_marital_status,
        COUNT(DISTINCT o.ws_order_number) AS order_count,
        COUNT(DISTINCT o.ws_item_sk) AS item_count,
        SUM(o.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales o ON c.c_customer_sk = o.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), 
detailed_report AS (
    SELECT 
        ci.c_customer_id,
        ci.gender,
        ci.cd_marital_status,
        CASE 
            WHEN ci.total_spent IS NULL THEN 'No Purchases'
            WHEN ci.total_spent < 100 THEN 'Low Spending'
            WHEN ci.total_spent BETWEEN 100 AND 500 THEN 'Medium Spending'
            ELSE 'High Spending'
        END AS spending_category,
        hs.i_product_name,
        hs.total_quantity,
        hs.total_sales
    FROM 
        customer_info ci
    JOIN 
        high_sales hs ON ci.item_count > 0
    WHERE 
        hs.total_quantity > 5
)
SELECT 
    dr.c_customer_id,
    dr.gender,
    dr.cd_marital_status,
    dr.spending_category,
    dr.i_product_name,
    dr.total_quantity,
    dr.total_sales
FROM 
    detailed_report dr
ORDER BY 
    dr.total_sales DESC;
