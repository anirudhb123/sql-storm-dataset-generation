
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, ws_ship_customer_sk, ws_item_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
       hd.hd_income_band_sk,
        CASE 
            WHEN cd.cd_buy_potential IS NULL THEN 'UNKNOWN'
            ELSE cd.cd_buy_potential
        END AS buying_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
TopCustomers AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(sd.total_quantity) AS total_purchased,
        SUM(sd.total_sales) AS total_spent
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        sd.sales_rank <= 10
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_purchased, 0) AS total_purchases,
    COALESCE(tc.total_spent, 0) AS total_spent,
    CASE 
        WHEN tc.total_spent > 500 THEN 'VIP'
        WHEN tc.total_spent BETWEEN 100 AND 500 THEN 'Regular'
        ELSE 'New'
    END AS customer_type,
    ci.buying_potential
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerInfo ci ON tc.c_customer_sk = ci.c_customer_sk
ORDER BY 
    total_spent DESC;
