
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d.d_year,
        d.d_month_seq,
        c.cd_gender,
        c.cd_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq, c.cd_gender, c.cd_income_band_sk
),
Ranking AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sold,
        sd.total_sales,
        sd.total_discount,
        sd.d_year,
        sd.d_month_seq,
        sd.cd_gender,
        sd.cd_income_band_sk,
        RANK() OVER (PARTITION BY sd.d_month_seq, sd.cd_gender ORDER BY sd.total_sales DESC) AS rank
    FROM 
        SalesData sd
)
SELECT 
    r.ws_item_sk,
    r.total_sold,
    r.total_sales,
    r.total_discount,
    r.d_year,
    r.d_month_seq,
    r.cd_gender,
    r.cd_income_band_sk
FROM 
    Ranking r
WHERE 
    r.rank <= 5
ORDER BY 
    r.d_month_seq, r.cd_gender, r.total_sales DESC;
