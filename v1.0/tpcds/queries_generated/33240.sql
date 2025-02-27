
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid) AS total_sales_value,
        ws_order_number,
        1 AS level
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_sales_quantity,
        SUM(cs_net_paid_inc_tax) AS total_sales_value,
        cs_order_number,
        level + 1
    FROM 
        catalog_sales
    INNER JOIN Sales_CTE ON Sales_CTE.ws_item_sk = cs_item_sk
    GROUP BY 
        cs_item_sk, cs_order_number, level
),
Sales_Summary AS (
    SELECT 
        ws_item_sk,
        SUM(total_sales_quantity) AS overall_sales_quantity,
        SUM(total_sales_value) AS overall_sales_value
    FROM 
        Sales_CTE
    GROUP BY 
        ws_item_sk
),
Customer_Segment AS (
    SELECT 
        CASE 
            WHEN cd_purchase_estimate BETWEEN 0 AND 499 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'High'
        END AS purchase_segment,
        SUM(cs_sales_value) AS total_value
    FROM 
        Sales_Summary
    LEFT JOIN customer_demographics ON customer_demographics.cd_demo_sk = Sales_CTE.ws_item_sk
    GROUP BY purchase_segment
)
SELECT 
    purchase_segment,
    total_value,
    ROW_NUMBER() OVER (ORDER BY total_value DESC) AS rank,
    COALESCE(SUM(total_value) OVER (PARTITION BY purchase_segment), 0) AS cumulative_value
FROM 
    Customer_Segment
FULL OUTER JOIN customer_address ON customer_address.ca_address_sk = NULL
WHERE 
    total_value > 10000
ORDER BY 
    purchase_segment;
