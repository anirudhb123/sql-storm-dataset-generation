
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_profit) > 0
),
best_selling_items AS (
    SELECT 
        i_item_id,
        i_item_desc,
        ss.total_quantity,
        ss.total_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_profit DESC) AS item_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10
)
SELECT 
    bsi.i_item_id,
    bsi.i_item_desc,
    bsi.total_quantity,
    bsi.total_profit,
    CA.ca_city AS customer_city,
    COALESCE(CC.cc_name, 'N/A') AS call_center_name,
    COUNT(DISTINCT C.c_customer_id) AS total_customers,
    CASE 
        WHEN bsi.total_profit > 10000 THEN 'High'
        WHEN bsi.total_profit BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM 
    best_selling_items bsi
LEFT JOIN 
    web_sales ws ON ws.ws_item_sk = bsi.ws_item_sk
LEFT JOIN 
    customer C ON ws.ws_bill_customer_sk = C.c_customer_sk
LEFT JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
LEFT JOIN 
    call_center CC ON CC.cc_call_center_sk = ws.ws_web_page_sk
WHERE 
    bsi.item_rank <= 10
GROUP BY 
    bsi.i_item_id, bsi.i_item_desc, bsi.total_quantity, bsi.total_profit, CA.ca_city, CC.cc_name
ORDER BY 
    bsi.total_profit DESC;
