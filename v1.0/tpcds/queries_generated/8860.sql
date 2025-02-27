
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        SUM(ws.ws_sales_price) AS total_web_sales_amount,
        SUM(ws.ws_quantity) AS total_web_qty,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
PopularItems AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(*) AS purchase_count,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        purchase_count DESC
    LIMIT 10
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    pi.ws_item_sk,
    pi.purchase_count,
    pi.total_quantity_sold,
    pi.avg_price,
    cs.total_web_sales,
    cs.total_web_sales_amount,
    cs.total_web_qty
FROM 
    CustomerStats cs
JOIN 
    PopularItems pi ON pi.ws_item_sk IN (
        SELECT ws.ws_item_sk 
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = cs.c_customer_sk
    )
ORDER BY 
    cs.total_web_sales_amount DESC;
