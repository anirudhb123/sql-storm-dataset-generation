
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
    FROM 
        ranked_customers AS c
    WHERE 
        c.purchase_rank <= 10
),
detailed_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales AS ws
    JOIN 
        top_customers AS tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ds.total_quantity,
    ds.total_sales,
    ds.avg_net_profit,
    COALESCE(NULLIF(i.i_current_price, 0), 1) * SUM(ds.total_quantity) AS projected_earnings,
    CASE 
        WHEN ds.total_sales > 0 THEN (ds.avg_net_profit / ds.total_sales)
        ELSE 0
    END AS profit_margin
FROM 
    item AS i
JOIN 
    detailed_sales AS ds ON i.i_item_sk = ds.ws_item_sk
LEFT JOIN 
    inventory AS inv ON i.i_item_sk = inv.inv_item_sk
WHERE 
    inv.inv_quantity_on_hand > 0
GROUP BY 
    i.i_item_id, i.i_product_name, ds.total_quantity, ds.total_sales, ds.avg_net_profit
ORDER BY 
    projected_earnings DESC
LIMIT 20;
