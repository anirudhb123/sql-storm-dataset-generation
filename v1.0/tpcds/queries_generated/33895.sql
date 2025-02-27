
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_sold_date_sk
    UNION ALL
    SELECT
        sd.d_date_sk,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number)
    FROM
        SalesCTE sc
    LEFT JOIN
        date_dim sd ON sd.d_date_sk = sc.ws_sold_date_sk + 1
    LEFT JOIN
        web_sales ws ON ws.ws_sold_date_sk = sd.d_date_sk
    WHERE
        sd.d_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        sd.d_date_sk
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        cd.cd_gender,
        cd.cd_marital_status
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.orders_count,
        cd.cd_education_status,
        CASE
            WHEN cs.total_spent >= 1000 THEN 'High' 
            WHEN cs.total_spent BETWEEN 500 AND 999 THEN 'Medium' 
            ELSE 'Low' 
        END AS spending_band
    FROM
        CustomerSales cs
    JOIN
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE
        cd.cd_marital_status = 'M'
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    h.total_spent,
    h.orders_count,
    h.spending_band
FROM 
    HighSpenders h
WHERE
    h.total_spent IS NOT NULL AND 
    h.orders_count > 5
ORDER BY 
    h.total_spent DESC
LIMIT 10;

