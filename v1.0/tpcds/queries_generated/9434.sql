
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, hd.hd_income_band_sk
),
TopSales AS (
    SELECT 
        customer_id,
        total_sales,
        order_count,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        hd_income_band_sk
    FROM 
        RankedSales
    WHERE 
        rank <= 10
)
SELECT 
    t.cd_gender,
    t.cd_marital_status,
    i.ib_lower_bound,
    i.ib_upper_bound,
    COUNT(t.customer_id) AS customer_count,
    AVG(t.total_sales) AS avg_sales,
    SUM(t.order_count) AS total_orders
FROM 
    TopSales t
JOIN 
    income_band i ON t.hd_income_band_sk = i.ib_income_band_sk
GROUP BY 
    t.cd_gender, t.cd_marital_status, i.ib_lower_bound, i.ib_upper_bound
ORDER BY 
    t.cd_gender, t.cd_marital_status, avg_sales DESC;
