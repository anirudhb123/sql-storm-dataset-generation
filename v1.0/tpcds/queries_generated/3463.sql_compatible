
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        MAX(ws_sales_price) AS max_sales_price,
        MIN(ws_sales_price) AS min_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dependents_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
TopCustomers AS (
    SELECT 
        cus.ws_bill_customer_sk,
        SUM(cus.total_profit) AS total_profit,
        COUNT(DISTINCT o.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(cus.total_profit) DESC) AS rn
    FROM 
        SalesSummary cus
    JOIN 
        web_sales o ON cus.ws_bill_customer_sk = o.ws_bill_customer_sk
    GROUP BY 
        cus.ws_bill_customer_sk
)

SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_dependents_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    tc.total_profit,
    tc.order_count
FROM 
    CustomerDemo cd
JOIN 
    TopCustomers tc ON cd.c_customer_sk = tc.ws_bill_customer_sk
WHERE 
    tc.rn <= 50
ORDER BY 
    tc.total_profit DESC;
