
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN 10101 AND 10130
    GROUP BY 
        ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        ik.ib_lower_bound,
        ik.ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(sd.total_sales) DESC) AS rank
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN SalesData sd ON sd.ws_item_sk IN (
        SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk
    )
    LEFT JOIN household_demographics hh ON hh.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_band ik ON ik.ib_income_band_sk = hh.hd_income_band_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_current_cdemo_sk, 
        cd.cd_gender, 
        ik.ib_lower_bound, 
        ik.ib_upper_bound
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.ib_lower_bound,
    cs.ib_upper_bound,
    cs.order_count,
    cs.total_sales,
    COALESCE(SUM(ss.ss_net_profit), 0) AS total_net_profit
FROM 
    CustomerStats cs
LEFT JOIN 
    store_sales ss ON cs.c_customer_sk = ss.ss_customer_sk 
WHERE 
    cs.rank <= 10
GROUP BY 
    cs.c_customer_sk, 
    cs.cd_gender, 
    cs.ib_lower_bound, 
    cs.ib_upper_bound, 
    cs.order_count, 
    cs.total_sales
ORDER BY 
    total_net_profit DESC;
