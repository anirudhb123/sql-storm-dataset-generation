
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
inventory_info AS (
    SELECT
        inv_item_sk,
        MAX(inv_quantity_on_hand) AS max_quantity,
        COUNT(DISTINCT inv_warehouse_sk) AS warehouse_count
    FROM
        inventory
    GROUP BY
        inv_item_sk
),
return_stats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM
        store_returns
    GROUP BY 
        sr_item_sk
),
combined_stats AS (
    SELECT
        is.ws_item_sk,
        COALESCE(is.total_sales, 0) AS total_sales,
        COALESCE(ii.max_quantity, 0) AS max_quantity,
        COALESCE(rs.total_returns, 0) AS total_returns,
        rounding_function(COALESCE(is.total_sales, 0) / NULLIF(ii.max_quantity, 0), 2) AS sales_per_inventory
    FROM
        ranked_sales is
    FULL OUTER JOIN
        inventory_info ii ON is.ws_item_sk = ii.inv_item_sk
    FULL OUTER JOIN
        return_stats rs ON is.ws_item_sk = rs.sr_item_sk
)
SELECT
    cs.c_current_cdemo_sk,
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_email_address,
    cbs.total_sales,
    cbs.max_quantity,
    cbs.total_returns,
    CASE 
        WHEN cbs.sales_per_inventory IS NULL THEN 'No Sales Data'
        ELSE 'Sales Data Available' 
    END AS sales_data_availability,
    ((cbs.total_sales - cbs.total_returns) / NULLIF(cbs.total_sales, 0)) * 100 AS net_sales_percentage
FROM 
    customer cs 
LEFT JOIN
    combined_stats cbs ON cs.c_current_cdemo_sk = cbs.ws_item_sk
WHERE 
    (cbs.total_sales > 100 OR cbs.total_returns <= 5)
    AND (cs.c_email_address LIKE '%@example.com' OR cs.c_birth_month IS NULL)
ORDER BY 
    net_sales_percentage DESC
LIMIT 100;
