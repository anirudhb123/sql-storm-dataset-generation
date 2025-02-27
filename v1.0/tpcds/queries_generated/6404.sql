
WITH SalesData AS (
    SELECT 
        ws.js_item_sk,
        COUNT(ws.ws_order_number) AS num_sales,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'F'
    GROUP BY 
        ws.ws_item_sk
),
AggregatedSales AS (
    SELECT 
        sd.js_item_sk,
        sd.num_sales,
        sd.total_sales,
        sd.total_discount,
        sd.total_tax,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    as.total_sales,
    as.total_discount,
    as.total_tax
FROM 
    AggregatedSales as
JOIN 
    item i ON as.js_item_sk = i.i_item_sk
WHERE 
    as.sales_rank <= 10
ORDER BY 
    as.total_sales DESC;
