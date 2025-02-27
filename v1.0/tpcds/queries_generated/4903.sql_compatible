
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 11000 AND 11200
    GROUP BY 
        w.w_warehouse_id
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate
    FROM 
        customer_info ci
    WHERE 
        ci.cd_purchase_estimate > 50000
),
returns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
join_summary AS (
    SELECT 
        s.ss_item_sk,
        s.ss_quantity,
        ss.total_orders,
        ss.total_sales,
        r.total_returns,
        r.total_return_amt,
        r.avg_return_quantity
    FROM 
        store_sales s
    LEFT JOIN 
        sales_summary ss ON s.ss_item_sk = ss.w_warehouse_id
    LEFT JOIN 
        returns r ON s.ss_item_sk = r.sr_item_sk
)
SELECT 
    js.ss_item_sk,
    js.ss_quantity,
    js.total_orders,
    js.total_sales,
    js.total_returns,
    js.total_return_amt,
    js.avg_return_quantity,
    CASE 
        WHEN js.total_sales > 1000 THEN 'High Sales'
        WHEN js.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
        ELSE 'Low Sales' 
    END AS sales_category,
    CUBE (js.total_orders, js.total_sales) AS order_sales_cube
FROM 
    join_summary js
WHERE 
    js.total_orders > 0
ORDER BY 
    js.total_sales DESC;
