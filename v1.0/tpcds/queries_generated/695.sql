
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) as rank
    FROM 
        web_sales ws
), 
customer_info AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) as total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
), 
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        AVG(ws.ws_sales_price) as avg_selling_price
    FROM 
        income_band ib
    LEFT JOIN 
        customer_info ci ON ci.cd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = ci.c_customer_sk
    WHERE 
        ci.total_orders > 5
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    id.avg_selling_price,
    COUNT(rs.ws_order_number) as total_top_sales
FROM 
    customer_info ci
LEFT JOIN 
    ranked_sales rs ON rs.ws_order_number IN (
        SELECT 
            ws_order_number 
        FROM 
            ranked_sales 
        WHERE 
            rank = 1
    )
LEFT JOIN 
    income_distribution id ON ci.cd_income_band_sk = id.ib_income_band_sk
GROUP BY 
    ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, id.avg_selling_price
HAVING 
    total_top_sales > 0
ORDER BY 
    avg_selling_price DESC
LIMIT 100;
