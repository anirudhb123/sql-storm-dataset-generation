
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        cd.purchase_count,
        p.promo_order_count
    FROM 
        SalesData sd
    LEFT JOIN 
        CustomerData cd ON sd.ws_item_sk IN (SELECT ws_item_sk FROM web_sales)
    LEFT JOIN 
        Promotions p ON p.promo_order_count > 0
    ORDER BY 
        sd.total_sales DESC
    LIMIT 10
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales,
    ts.purchase_count,
    ts.promo_order_count
FROM 
    TopSales ts
WHERE 
    ts.total_quantity > 100 AND 
    ts.purchase_count > 5
ORDER BY 
    ts.total_sales DESC;
