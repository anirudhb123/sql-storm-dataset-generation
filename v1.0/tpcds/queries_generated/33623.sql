
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
address_count AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_state
),
promotions AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws_order_number) AS promo_sales_count
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
),
high_performing_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        ac.customer_count,
        ROW_NUMBER() OVER (ORDER BY sd.total_profit DESC) AS rank
    FROM 
        sales_data sd
    LEFT JOIN 
        address_count ac ON ac.customer_count > 100
    WHERE 
        sd.rn = 1
)
SELECT 
    hi.ws_item_sk,
    hi.total_quantity,
    hi.total_profit,
    ac.customer_count,
    p.promo_sales_count
FROM 
    high_performing_items hi
LEFT JOIN 
    address_count ac ON ac.customer_count IS NOT NULL
LEFT JOIN 
    promotions p ON p.promo_sales_count > 0
WHERE 
    hi.rank <= 10
ORDER BY 
    hi.total_profit DESC;
