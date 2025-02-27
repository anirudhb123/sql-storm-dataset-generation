
WITH RECURSIVE SalesDaily AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        SUM(ws_ext_sales_price) AS total_spent,
        cd.cd_gender,
        ib.ib_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, ib.ib_income_band_sk
),
TopCustomers AS (
    SELECT 
        c.*,
        cs.total_spent
    FROM 
        customer c
    JOIN 
        CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_spent IS NOT NULL
        AND cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats) 
)
SELECT 
    T.c_customer_sk,
    T.total_spent,
    T.cd_gender,
    S.total_quantity,
    S.total_sales,
    (SELECT COUNT(DISTINCT ws_order_number) FROM web_sales ws WHERE ws.ws_bill_customer_sk = T.c_customer_sk) AS order_count
FROM 
    TopCustomers T
JOIN 
    SalesDaily S ON T.c_first_sales_date_sk = S.ws_sold_date_sk
WHERE 
    T.cd_gender IS NOT NULL
ORDER BY 
    T.total_spent DESC, S.total_sales DESC
LIMIT 100;
