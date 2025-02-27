
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        s.ws_item_sk,
        i.i_item_desc,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_orders, 0) AS total_orders
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    INNER JOIN 
        (SELECT ws_item_sk FROM sales_summary WHERE rnk <= 10) s ON i.i_item_sk = s.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_id, cd.cd_gender
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.order_count,
    ci.total_spent,
    ts.total_sales,
    ts.total_orders
FROM 
    customer_info ci
FULL OUTER JOIN 
    top_sales ts ON ci.order_count > 0 AND ts.total_sales > 1000
WHERE 
    (ci.cd_gender = 'M' OR ci.cd_gender = 'F')
    AND (ci.total_spent IS NOT NULL OR ts.total_sales IS NOT NULL)
ORDER BY 
    ci.total_spent DESC, ts.total_sales ASC;
