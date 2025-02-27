
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_income_band_sk,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year >= 1980
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2022)
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_net_profit,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM 
        SalesData sd
)
SELECT 
    ci.c_first_name AS customer_first_name,
    ci.c_last_name AS customer_last_name,
    ci.cd_gender AS customer_gender,
    ti.total_quantity_sold,
    ti.total_net_profit
FROM 
    CustomerInfo ci
LEFT JOIN 
    TopItems ti ON ci.c_customer_sk IN (SELECT sr_refunded_customer_sk 
                                          FROM store_returns 
                                          WHERE sr_item_sk = ti.ws_item_sk)
WHERE 
    ci.gender_rank = 1
    AND ti.profit_rank <= 10
ORDER BY 
    ti.total_net_profit DESC;
