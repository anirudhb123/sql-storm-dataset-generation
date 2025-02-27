
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        dr.total_return_quantity
    FROM customer c
    JOIN RankedReturns dr ON c.c_customer_sk = dr.sr_customer_sk
    WHERE dr.rn = 1
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT CASE WHEN ws_net_paid > 100 THEN ws_order_number END) AS high_value_orders
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ib_lower_bound,
    cd.ib_upper_bound,
    cd.high_value_orders,
    COALESCE(cd.high_value_orders, 0) AS high_value_orders,
    CASE 
        WHEN cd.high_value_orders > 10 THEN 'High'
        WHEN cd.high_value_orders BETWEEN 1 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS order_value_category
FROM TopCustomers tc
LEFT JOIN CustomerDemographics cd ON tc.c_customer_id = CONCAT('C', cd.cd_demo_sk)
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_customer_sk = tc.c_customer_id
    AND ss.ss_sales_price > 50
)
ORDER BY cd.high_value_orders DESC, tc.c_last_name, tc.c_first_name;
