
WITH RECURSIVE sales_trend AS (
    SELECT 
        d.d_date AS sales_date, 
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY d.d_date DESC) AS date_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_date
),
customer_incomes AS (
    SELECT 
        c.c_customer_sk,
        coalesce(hd.hd_income_band_sk, ib.ib_income_band_sk) as income_band,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, income_band
),
sales_return AS (
    SELECT 
        sr_item_sk, 
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ci.income_band,
    COALESCE(st.sales_date, DATE '2023-01-01') AS last_purchase_date,
    COALESCE(st.total_sales, 0) AS last_month_sales,
    SUM(COALESCE(sr.total_returns, 0)) AS total_item_returns,
    ROUND(AVG(coalesce(sp.total_spent, 0)), 2) AS average_spent
FROM 
    customer c
LEFT JOIN 
    customer_incomes ci ON c.c_customer_sk = ci.c_customer_sk
LEFT JOIN 
    sales_trend st ON c.c_first_sales_date_sk = st.date_rank
LEFT JOIN 
    sales_return sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    (SELECT ws_bill_customer_sk, SUM(ws.net_paid) AS total_spent
     FROM web_sales
     GROUP BY ws_bill_customer_sk) sp ON c.c_customer_sk = sp.ws_bill_customer_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ci.income_band, 
    last_purchase_date
HAVING 
    SUM(COALESCE(sr.total_returns, 0)) < 5
ORDER BY 
    average_spent DESC;
