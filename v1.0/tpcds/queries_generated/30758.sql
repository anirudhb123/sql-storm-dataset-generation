
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        1 AS level
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number

    UNION ALL

    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) + cte.total_quantity AS total_quantity,
        SUM(ws.ws_net_paid) + cte.total_sales AS total_sales,
        level + 1
    FROM 
        web_sales ws
    JOIN Sales_CTE cte ON ws.ws_item_sk = cte.ws_item_sk AND ws.ws_order_number IS NOT NULL
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number, cte.total_quantity, cte.total_sales, level
),

Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        CASE
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

Address_Info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city) AS full_address
    FROM 
        customer_address ca
),

Sales_with_Address AS (
    SELECT 
        cinfo.c_customer_sk,
        cinfo.c_first_name,
        cinfo.c_last_name,
        cinfo.cd_gender,
        cinfo.marital_status,
        ainfo.full_address,
        cte.total_quantity,
        cte.total_sales
    FROM 
        Customer_Info cinfo 
    LEFT JOIN 
        Address_Info ainfo ON cinfo.c_customer_sk = ainfo.ca_address_sk
    LEFT JOIN 
        Sales_CTE cte ON cinfo.c_customer_sk = cte.ws_order_number
)

SELECT 
    sw.*,
    CASE
        WHEN sw.total_sales IS NULL THEN 'No Sales'
        WHEN sw.total_sales > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    ROW_NUMBER() OVER (PARTITION BY sw.marital_status ORDER BY sw.total_sales DESC) AS rn
FROM 
    Sales_with_Address sw
WHERE 
    sw.total_quantity IS NOT NULL
ORDER BY 
    sw.total_sales DESC
LIMIT 100;
