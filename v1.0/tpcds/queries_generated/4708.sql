
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rn,
        COALESCE(cc.cc_call_center_id, 'N/A') as call_center_id,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) as total_quantity_sold,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) as profit_rank
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        call_center cc ON c.c_current_hdemo_sk = cc.cc_call_center_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2452045 AND 2452045 + 30
        AND cd.cd_gender IS NOT NULL
)

SELECT 
    s.ws_item_sk,
    s.ws_order_number,
    s.ws_quantity,
    s.ws_sales_price,
    s.ws_net_profit,
    s.call_center_id,
    s.ca_city,
    s.ca_state,
    s.cd_gender,
    s.cd_marital_status,
    s.total_quantity_sold,
    s.profit_rank
FROM 
    SalesData s
WHERE 
    s.rn = 1 
    OR (s.profit_rank <= 10 AND s.cd_marital_status = 'M')
ORDER BY 
    s.ws_net_profit DESC
LIMIT 100 
UNION 
SELECT 
    s.ws_item_sk,
    s.ws_order_number,
    s.ws_quantity,
    s.ws_sales_price,
    s.ws_net_profit,
    s.call_center_id,
    s.ca_city,
    s.ca_state,
    s.cd_gender,
    s.cd_marital_status,
    s.total_quantity_sold,
    s.profit_rank
FROM 
    SalesData s
WHERE 
    s.rn > 1 
    AND s.ca_state IS NOT NULL
    AND s.total_quantity_sold < 5
ORDER BY 
    s.ws_net_profit DESC
LIMIT 100;
