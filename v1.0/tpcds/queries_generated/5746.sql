
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
BorderCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_orders,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        hd.hd_income_band_sk IS NOT NULL
    HAVING 
        total_sales > (SELECT AVG(total_sales) FROM CustomerSales) 
        AND total_orders > (SELECT AVG(total_orders) FROM CustomerSales)
),
SalesDetails AS (
    SELECT 
        b.c_customer_sk,
        b.total_sales,
        b.total_orders,
        COUNT(ws.ws_item_sk) AS items_purchased,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        BorderCustomers b
    JOIN 
        web_sales ws ON b.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        b.c_customer_sk, b.total_sales, b.total_orders
)
SELECT 
    d.d_date,
    COUNT(DISTINCT sd.c_customer_sk) AS customer_count,
    SUM(sd.total_sales) AS total_sales_volume,
    AVG(sd.items_purchased) AS avg_items_per_customer,
    AVG(sd.total_discount) AS avg_discount_per_order,
    AVG(sd.total_tax) AS avg_tax_per_order
FROM 
    SalesDetails sd
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_ship_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = sd.c_customer_sk)
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_date
ORDER BY 
    d.d_date;
