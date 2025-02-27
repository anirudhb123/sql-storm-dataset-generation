
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.ws_item_sk, ws.ws_sales_price, ws.ws_ship_date_sk, d.d_year, d.d_month_seq, d.d_week_seq
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT sd.total_quantity) AS total_items_bought,
        SUM(sd.total_sales) AS lifetime_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON sd.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.total_items_bought,
    cd.lifetime_value,
    ROW_NUMBER() OVER (ORDER BY cd.lifetime_value DESC) AS rank
FROM 
    CustomerData cd
WHERE 
    cd.lifetime_value > 1000
ORDER BY 
    cd.lifetime_value DESC
LIMIT 50;
