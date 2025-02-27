
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_state,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_state, cd.cd_gender
)
SELECT 
    cs.c_state,
    cs.cd_gender,
    SUM(cs.total_orders) AS aggregate_orders,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    AVG(cs.total_spent) AS avg_spent,
    COALESCE(r.total_sales, 0) AS total_sales_by_item
FROM 
    CustomerStats cs
LEFT JOIN 
    RankedSales r ON cs.c_customer_sk = r.ws_item_sk
GROUP BY 
    cs.c_state, cs.cd_gender
HAVING 
    aggregate_orders > 10
ORDER BY 
    aggregate_orders DESC, avg_spent DESC;
