
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        EXTRACT(YEAR FROM d.d_date) AS sale_year,
        EXTRACT(MONTH FROM d.d_date) AS sale_month
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2022
    GROUP BY 
        ws.ws_item_sk, sale_year, sale_month
),
AverageSales AS (
    SELECT 
        sale_year,
        sale_month,
        AVG(total_quantity) AS avg_quantity,
        AVG(total_net_paid) AS avg_net_paid,
        AVG(total_discount) AS avg_discount
    FROM 
        SalesData
    GROUP BY 
        sale_year, sale_month
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        asales.sale_year,
        asales.sale_month,
        asales.avg_quantity,
        asales.avg_net_paid,
        asales.avg_discount
    FROM 
        AverageSales asales
    JOIN 
        item i ON asales.sale_year = (SELECT MAX(sale_year) FROM AverageSales)
    WHERE 
        asales.avg_quantity IN (SELECT DISTINCT avg_quantity FROM AverageSales WHERE sale_year = asales.sale_year)
    ORDER BY 
        asales.avg_net_paid DESC
    LIMIT 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.sale_year,
    ti.sale_month,
    ti.avg_quantity,
    ti.avg_net_paid,
    ti.avg_discount
FROM 
    TopItems ti
JOIN 
    customer_demographics cd ON EXISTS (SELECT 1 FROM web_sales ws JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk WHERE c.c_current_cdemo_sk = cd.cd_demo_sk)
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    ti.sale_year, ti.sale_month, ti.avg_net_paid DESC;
