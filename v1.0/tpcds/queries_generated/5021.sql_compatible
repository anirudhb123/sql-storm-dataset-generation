
WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        cs.cs_sales_price,
        cs.cs_quantity,
        ss.ss_sales_price,
        ss.ss_quantity,
        d.d_year,
        d.d_month_seq,
        c.cd_gender,
        c.cd_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
)
SELECT 
    d_year,
    d_month_seq,
    cd_gender,
    cd_income_band_sk,
    SUM(ws_sales_price * ws_quantity) AS total_web_sales,
    SUM(cs_sales_price * cs_quantity) AS total_catalog_sales,
    SUM(ss_sales_price * ss_quantity) AS total_store_sales
FROM 
    SalesData
GROUP BY 
    d_year, 
    d_month_seq, 
    cd_gender,
    cd_income_band_sk
HAVING 
    SUM(ws_sales_price * ws_quantity) > 5000
ORDER BY 
    d_year DESC, d_month_seq DESC, total_web_sales DESC;
