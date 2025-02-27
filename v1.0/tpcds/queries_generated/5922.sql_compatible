
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458825 AND 2458831
    GROUP BY 
        ws_order_number, ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        item.i_current_price,
        sales.total_quantity,
        sales.total_net_paid
    FROM 
        RankedSales AS sales
    JOIN 
        item AS item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rank <= 10
),
CustomerPurchase AS (
    SELECT 
        c.c_customer_id,
        SUM(s.total_net_paid) AS total_spent
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        TopItems AS ti ON ws.ws_item_sk = ti.ws_item_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cp.c_customer_id,
    cp.total_spent,
    ROW_NUMBER() OVER (ORDER BY cp.total_spent DESC) AS rank,
    COUNT(CASE WHEN ti.total_quantity > 1 THEN 1 END) AS frequent_buyer_items
FROM 
    CustomerPurchase AS cp
JOIN 
    web_sales AS ws ON cp.c_customer_id = ws.ws_bill_customer_sk
JOIN 
    TopItems AS ti ON ws.ws_item_sk = ti.ws_item_sk
GROUP BY 
    cp.c_customer_id, cp.total_spent
ORDER BY 
    cp.total_spent DESC;
