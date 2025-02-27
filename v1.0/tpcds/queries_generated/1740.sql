
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        w.w_warehouse_name,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
),
aggregated_data AS (
    SELECT 
        w.w_warehouse_name,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        SUM(ws_quantity * ws_sales_price) AS total_revenue
    FROM
        sales_data sd
    GROUP BY 
        w.w_warehouse_name
),
returns_data AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    ad.w_warehouse_name,
    ad.unique_customers,
    ad.total_revenue,
    COALESCE(rd.total_returns, 0) AS total_returns,
    (ad.total_revenue - COALESCE(rd.total_returns, 0)) AS net_revenue
FROM 
    aggregated_data ad
LEFT JOIN 
    returns_data rd ON ad.w_warehouse_name = (
        SELECT w.w_warehouse_name 
        FROM warehouse w 
        WHERE w.w_warehouse_sk = rd.sr_store_sk
    )
WHERE 
    ad.total_revenue > 1000.00
ORDER BY 
    net_revenue DESC;
