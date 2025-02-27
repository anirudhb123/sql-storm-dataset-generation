
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price IS NOT NULL
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand
    FROM
        inventory inv
    WHERE
        inv.inv_quantity_on_hand > 0
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
        AND cd.cd_gender IN ('M', 'F') 
),
returns_data AS (
    SELECT
        sr.returning_customer_sk,
        SUM(sr.return_quantity) AS total_returned,
        AVG(sr.net_loss) AS avg_net_loss
    FROM
        store_returns sr
    GROUP BY
        sr.returning_customer_sk
),
item_sales_data AS (
    SELECT
        item.i_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM
        item item
    LEFT JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY 
        item.i_item_sk
)
SELECT
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.purchase_rank,
    ss.item_count,
    ss.total_sales,
    ss.unique_customers,
    COALESCE(r.total_returned, 0) AS total_returned,
    COALESCE(r.avg_net_loss, 0) AS avg_net_loss,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    customer_info ci
LEFT JOIN 
    item_sales_data ss ON ci.c_customer_sk = ss.item_count
LEFT JOIN 
    returns_data r ON ci.c_customer_sk = r.returning_customer_sk
WHERE
    ci.purchase_rank <= 10
    AND (ci.cd_marital_status IS NULL OR ci.cd_marital_status IN ('M', 'S'))
ORDER BY
    ci.cd_purchase_estimate DESC NULLS LAST;
