
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        ranked_customers rc ON ws.ws_bill_customer_sk = rc.c_customer_sk
    WHERE 
        rc.purchase_rank <= 10
    GROUP BY 
        ws.ws_item_sk
),
high_demand_items AS (
    SELECT 
        is.ws_item_sk,
        is.total_quantity,
        is.total_profit,
        i.i_product_name,
        i.i_current_price,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Price Not Available'
            ELSE CAST(i.i_current_price AS VARCHAR(20))
        END AS current_price_str
    FROM 
        item_sales is
    JOIN 
        item i ON is.ws_item_sk = i.i_item_sk
    WHERE 
        is.total_quantity > (
            SELECT 
                AVG(total_quantity) FROM item_sales
        )
)
SELECT 
    hdi.ws_item_sk,
    hdi.i_product_name,
    hdi.total_quantity,
    hdi.total_profit,
    COALESCE(hdi.current_price_str, 'Price Not Found') AS display_price,
    CASE 
        WHEN hdi.total_profit > 1000 THEN 'High Profit'
        WHEN hdi.total_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    high_demand_items hdi
LEFT JOIN 
    store s ON hdi.ws_item_sk = s.s_store_sk
WHERE 
    (s.s_state IS NULL OR s.s_state = 'CA')
    AND (hdi.total_quantity IS NOT NULL OR hdi.total_profit IS NOT NULL)
ORDER BY 
    hdi.total_quantity DESC, hdi.total_profit DESC;
