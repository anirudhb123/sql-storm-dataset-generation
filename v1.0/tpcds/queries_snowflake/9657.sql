
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2452050
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND hd.hd_income_band_sk IS NOT NULL
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
    WHERE 
        sd.total_quantity > 100
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ti.ws_item_sk,
    ti.total_sales,
    ti.total_quantity
FROM 
    CustomerData ci
JOIN 
    TopItems ti ON ci.c_customer_sk IN (
        SELECT 
            DISTINCT ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk = ti.ws_item_sk
    )
WHERE 
    sales_rank <= 10
ORDER BY 
    ci.c_last_name, ci.c_first_name;
