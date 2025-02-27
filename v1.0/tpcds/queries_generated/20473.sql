
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.ws_item_sk
),
HighValueCust AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate > 10000 THEN 'High Value'
            ELSE 'Low Value' 
        END AS customer_value_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
),
SaleStats AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        RankedSales rs ON ws.ws_item_sk = rs.ws_item_sk
    WHERE 
        rs.sales_rank = 1
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cvc.customer_value_category,
    ss.total_sales,
    ss.order_count,
    i.i_item_desc,
    COALESCE(ROUND((ss.total_sales / NULLIF(ss.order_count, 0)), 2), 0) AS avg_sales_per_order
FROM 
    HighValueCust cvc
JOIN 
    SaleStats ss ON cvc.c_customer_sk = ss.ws_item_sk
JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer_address ca ON cvc.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IN ('NY', 'CA', 'TX')
ORDER BY 
    ss.total_sales DESC, c.c_last_name ASC
FETCH FIRST 50 ROWS ONLY
UNION ALL
SELECT 
    NULL AS c_first_name,
    NULL AS c_last_name,
    'No Purchases' AS customer_value_category,
    0 AS total_sales,
    0 AS order_count,
    i.i_item_desc,
    0 AS avg_sales_per_order
FROM 
    item i
WHERE 
    i.i_item_sk NOT IN (SELECT ws.ws_item_sk FROM web_sales ws)
ORDER BY 
    total_sales DESC;
