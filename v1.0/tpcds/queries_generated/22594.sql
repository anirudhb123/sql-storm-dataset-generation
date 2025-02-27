
WITH RECURSIVE CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER(PARTITION BY c.c_customer_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL
    UNION ALL
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.ws_order_number,
        cs.ws_sales_price * 0.9, -- applying a 10% discount to simulate recursive sales
        cs.ws_net_profit * 0.9,
        ROW_NUMBER() OVER(PARTITION BY cs.c_customer_sk ORDER BY cs.ws_net_profit DESC) AS rn
    FROM 
        CustomerSales cs
    WHERE 
        EXISTS (
            SELECT 1 
            FROM customer_address ca 
            WHERE ca.ca_address_sk = cs.c_customer_sk AND ca.ca_zip IS NOT NULL
        )
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(cs.ws_sales_price) AS total_sales_price,
        SUM(cs.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.ws_order_number) AS order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.rn = 1
    GROUP BY 
        c.c_customer_id
    HAVING 
        COUNT(DISTINCT cs.ws_order_number) > 1
)
SELECT 
    css.c_customer_id,
    CASE 
        WHEN css.total_sales_price > 1000 THEN 'High'
        WHEN css.total_sales_price BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    css.total_sales_price,
    (SELECT AVG(total_net_profit) 
     FROM SalesSummary 
     WHERE total_net_profit > 0) AS avg_net_profit_above_zero,
    COALESCE(MAX(sm.sm_type), 'No Shipping') AS preferred_shipping
FROM 
    SalesSummary css
LEFT JOIN 
    web_sales ws ON css.c_customer_id = ws.ws_bill_customer_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY 
    css.c_customer_id, css.total_sales_price
ORDER BY 
    sales_category DESC, css.total_sales_price DESC
LIMIT 50;
