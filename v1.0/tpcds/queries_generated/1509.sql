
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2410
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
MaxSales AS (
    SELECT 
        ws_item_sk,
        MAX(total_sales) AS max_sales
    FROM 
        SalesData
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_quantity,
        ms.max_sales
    FROM 
        SalesData sd
    JOIN 
        MaxSales ms ON sd.ws_item_sk = ms.ws_item_sk
    WHERE 
        sd.total_sales = ms.max_sales
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name,
        d.d_date
    FROM 
        customer c 
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
)
SELECT 
    cd.c_first_name || ' ' || cd.c_last_name AS customer_name,
    COUNT(DISTINCT ti.ws_item_sk) AS items_purchased,
    SUM(sd.total_quantity) AS total_quantity_purchased,
    CASE 
        WHEN SUM(sd.total_sales) IS NULL THEN 0 
        ELSE SUM(sd.total_sales) 
    END AS total_sales
FROM 
    CustomerDetails cd
LEFT JOIN 
    TopItems ti ON cd.c_customer_id = ti.ws_item_sk
LEFT JOIN 
    SalesData sd ON ti.ws_item_sk = sd.ws_item_sk
GROUP BY 
    cd.c_first_name, 
    cd.c_last_name
HAVING 
    SUM(sd.total_sales) > 0
ORDER BY 
    total_sales DESC
LIMIT 10;
