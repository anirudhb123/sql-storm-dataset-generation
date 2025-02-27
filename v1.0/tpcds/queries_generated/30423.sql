
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 60
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS ranking
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.total_quantity > 50
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM SalesData) 
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ti.i_item_desc,
    ti.total_sales,
    ti.total_quantity,
    cp.order_count,
    cp.total_spent,
    CASE 
        WHEN cp.total_spent IS NULL THEN 'No Purchases'
        ELSE CONCAT('Spent: ', TRIM(TO_CHAR(cp.total_spent, '$999,999.99')) )
    END AS purchase_summary
FROM 
    TopItems ti
LEFT JOIN 
    CustomerPurchases cp ON ti.ws_item_sk = cp.c_customer_sk
WHERE 
    ti.ranking <= 10
ORDER BY 
    ti.total_sales DESC;
