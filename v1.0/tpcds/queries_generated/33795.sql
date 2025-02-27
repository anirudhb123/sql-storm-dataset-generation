
WITH RECURSIVE sales_cte AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_item_sk

    UNION ALL

    SELECT
        cs_item_sk,
        SUM(cs_quantity),
        SUM(cs_ext_sales_price)
    FROM
        catalog_sales
    GROUP BY
        cs_item_sk
),
sales_summary AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        COALESCE(sc.total_quantity, 0) AS total_quantity,
        COALESCE(sc.total_sales, 0) AS total_sales,
        CASE
            WHEN COALESCE(sc.total_sales, 0) > 0 THEN 'Above Target'
            ELSE 'Below Target'
        END AS sales_status
    FROM
        item
    LEFT JOIN sales_cte sc ON item.i_item_sk = sc.ws_item_sk
)
SELECT
    ss.i_item_id,
    ss.i_item_desc,
    ss.total_quantity,
    ss.total_sales,
    ss.sales_status,
    CASE
        WHEN ss.sales_status = 'Below Target' THEN 'Alert: Sales Below Target!'
        ELSE 'Sales Performance Normal'
    END AS performance_message
FROM
    sales_summary ss
JOIN (
    SELECT 
        d_year,
        COUNT(DISTINCT s_store_sk) AS store_count
    FROM 
        store_sales 
    JOIN 
        date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    GROUP BY 
        d_year
) AS store_stats ON ss.total_quantity > store_stats.store_count
WHERE
    ss.total_quantity > 100
ORDER BY
    ss.total_sales DESC
LIMIT 50;

SELECT
    customer.c_customer_id,
    SUM(ws_net_profit) AS total_profit
FROM 
    web_sales ws
JOIN 
    customer ON ws.ws_bill_customer_sk = customer.c_customer_sk
WHERE 
    customer.c_birth_year IS NOT NULL
GROUP BY 
    customer.c_customer_id
HAVING 
    total_profit > (SELECT AVG(total_profit) FROM 
                     (SELECT SUM(ws_net_profit) AS total_profit
                      FROM web_sales
                      GROUP BY ws_bill_customer_sk) as avg_profit)
ORDER BY 
    total_profit DESC;

SELECT
    'Web Sales' AS sales_type,
    SUM(ws_ext_sales_price) AS total_sales
FROM
    web_sales
WHERE
    ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_carrier = 'FedEx')
UNION ALL
SELECT
    'Store Sales' AS sales_type,
    SUM(ss_ext_sales_price) AS total_sales
FROM
    store_sales
WHERE
    ss_store_sk IN (SELECT s_store_sk FROM store WHERE s_city = 'San Francisco')
ORDER BY
    total_sales DESC;
