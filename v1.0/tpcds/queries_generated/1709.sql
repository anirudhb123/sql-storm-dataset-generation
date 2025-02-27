
WITH SalesStats AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        ss_item_sk,
        total_quantity, 
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        SalesStats
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_item_sk) AS distinct_items_bought
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    tt.total_quantity,
    tt.total_profit,
    cp.order_count,
    cp.distinct_items_bought
FROM 
    TopItems tt
JOIN 
    inventory inv ON tt.ss_item_sk = inv.inv_item_sk
JOIN 
    CustomerPurchases cp ON cp.c_customer_sk = tt.ss_customer_sk
JOIN 
    customer c ON c.c_customer_sk = cp.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tt.profit_rank <= 10 
    AND (ca.ca_state IS NOT NULL OR cd.cd_gender = 'F')
ORDER BY 
    tt.total_profit DESC, 
    cp.order_count DESC;
