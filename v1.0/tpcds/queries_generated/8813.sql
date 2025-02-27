
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_sales,
        ri.order_count,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        RankedSales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.rank <= 10
), CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        total_orders > 5
)
SELECT 
    ti.i_item_desc,
    ti.total_sales,
    ti.order_count,
    cp.total_orders,
    cp.total_spent,
    cp.avg_order_value
FROM 
    TopItems ti
JOIN 
    CustomerPurchase cp ON ti.ws_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_order_number = cp.total_orders LIMIT 1)
ORDER BY 
    ti.total_sales DESC, cp.total_spent DESC
LIMIT 50;
