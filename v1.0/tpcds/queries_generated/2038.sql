
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
MaxSales AS (
    SELECT 
        c_customer_sk,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    MAX(inv.inv_quantity_on_hand) AS max_inventory,
    (SELECT COUNT(*) FROM store s 
     WHERE s.s_state = 'CA') AS total_stores_in_ca
FROM 
    CustomerSales cs
JOIN 
    inventory inv ON inv.inv_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = cs.c_customer_sk)
JOIN 
    MaxSales ms ON cs.c_customer_sk = ms.c_customer_sk
WHERE 
    ms.sales_rank <= 10
GROUP BY 
    cs.c_customer_id, cs.total_sales, cs.order_count
ORDER BY 
    cs.total_sales DESC;
