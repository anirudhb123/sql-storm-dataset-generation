
WITH RECURSIVE sales_summary AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS item_rank
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
    UNION ALL
    SELECT 
        ss.i_item_id,
        ss.total_quantity,
        ss.total_sales * 1.05 AS total_sales, -- simulate sale increase
        ss.order_count,
        ss.item_rank
    FROM 
        sales_summary ss
    WHERE 
        ss.item_rank < 10
),
top_sales AS (
    SELECT 
        i.i_item_id,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        ss.item_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON i.i_item_id = ss.i_item_id
    WHERE 
        ss.item_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        d.d_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        IFNULL(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
sales_with_customer AS (
    SELECT 
        ts.i_item_id,
        ts.total_quantity,
        ts.total_sales,
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.income_band
    FROM 
        top_sales ts
    CROSS JOIN 
        customer_info ci
)
SELECT 
    swc.i_item_id,
    SUM(swc.total_quantity) AS total_quantity_sold,
    SUM(swc.total_sales) AS total_sales_value,
    AVG(swc.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(swc.cd_marital_status) AS most_common_marital_status
FROM 
    sales_with_customer swc
GROUP BY 
    swc.i_item_id
HAVING 
    total_sales_value > 10000
ORDER BY 
    total_sales_value DESC
LIMIT 10;
