
WITH ranked_sales AS (
    SELECT 
        w.warehouse_name,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws_inner.ws_sales_price) FROM web_sales ws_inner) 
    GROUP BY 
        w.warehouse_name, i.i_item_desc
),
filtered_sales AS (
    SELECT 
        warehouse_name,
        i_item_desc,
        total_quantity,
        rank
    FROM 
        ranked_sales
    WHERE 
        rank <= 5
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(hd.hd_buy_potential, 'None') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
reference_data AS (
    SELECT 
        r.r_reason_desc,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        r.r_reason_desc
),
final_report AS (
    SELECT 
        cs.warehouse_name,
        cs.i_item_desc,
        cs.total_quantity,
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        rd.r_reason_desc,
        COALESCE(rd.total_returns, 0) AS returns_count
    FROM 
        filtered_sales cs
    JOIN 
        customer_details cd ON cd.c_customer_id = (SELECT c.c_customer_id FROM customer c ORDER BY RANDOM() LIMIT 1)
    LEFT JOIN 
        reference_data rd ON rd.total_returns > 0
)
SELECT 
    warehouse_name,
    i_item_desc,
    total_quantity,
    c_customer_id,
    cd_gender,
    cd_marital_status,
    r_reason_desc,
    returns_count
FROM 
    final_report
ORDER BY 
    total_quantity DESC;
