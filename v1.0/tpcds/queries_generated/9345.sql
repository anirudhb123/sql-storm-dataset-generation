
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        item i
    JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.rank <= 10
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    cs.c_customer_id,
    cs.order_count,
    cs.total_spent
FROM 
    TopItems ti
JOIN 
    CustomerStats cs ON cs.total_spent > 1000
ORDER BY 
    ti.total_sales DESC, cs.order_count DESC;
