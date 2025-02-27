
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_performance AS (
    SELECT 
        i.i_item_id,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
return_statistics AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
item_sales_summary AS (
    SELECT 
        ip.i_item_id,
        ip.avg_sales_price,
        ip.total_quantity_sold,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        (ip.total_quantity_sold - COALESCE(rs.total_returns, 0)) AS net_sales,
        (ip.total_quantity_sold * ip.avg_sales_price) - COALESCE(rs.total_return_amount, 0) AS net_revenue
    FROM 
        item_performance ip
    LEFT JOIN 
        return_statistics rs ON ip.i_item_id = rs.sr_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ias.i_item_id,
    ias.avg_sales_price,
    ias.total_quantity_sold,
    ias.total_returns,
    ias.total_return_amount,
    ias.net_sales,
    ias.net_revenue
FROM 
    customer_info ci
JOIN 
    item_sales_summary ias ON ci.purchase_rank <= 5
ORDER BY 
    ci.c_customer_id, ias.net_revenue DESC
LIMIT 10;
