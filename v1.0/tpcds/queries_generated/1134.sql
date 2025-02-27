
WITH SalesSummary AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),

TopItems AS (
    SELECT 
        ss_item_sk,
        total_quantity_sold,
        total_net_profit,
        order_count,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
        RANK() OVER (ORDER BY total_quantity_sold DESC) AS quantity_rank
    FROM 
        SalesSummary
),

CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    MIN(ws.ws_ship_date_sk) AS first_ship_date,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(ws.ws_net_paid) AS avg_spent_per_order,
    COALESCE(MAX(ts.total_quantity_sold), 0) AS max_quantity_sold
FROM 
    CustomerDetails c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    TopItems ts ON ws.ws_item_sk = ts.ss_item_sk
WHERE 
    ws.ws_ship_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender
HAVING 
    AVG(ws.ws_net_paid) > 100 AND 
    COUNT(DISTINCT ws.ws_order_number) > 1
ORDER BY 
    total_spent DESC
LIMIT 10;
