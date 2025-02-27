
WITH SalesAggregation AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_moy IN (11, 12) 
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
), 
TopSellingItems AS (
    SELECT 
        sa.ws_sold_date_sk, 
        sa.ws_item_sk, 
        sa.total_quantity_sold, 
        sa.total_net_profit
    FROM 
        SalesAggregation sa
    WHERE 
        sa.profit_rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ti.ws_sold_date_sk, 
    ti.ws_item_sk, 
    ti.total_quantity_sold, 
    ti.total_net_profit,
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender,
    ci.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    TopSellingItems ti
JOIN 
    web_sales ws ON ti.ws_item_sk = ws.ws_item_sk AND ti.ws_sold_date_sk = ws.ws_sold_date_sk
JOIN 
    CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
LEFT JOIN 
    household_demographics hd ON ci.cd_income_band_sk = hd.hd_income_band_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ti.ws_sold_date_sk, 
    ti.total_net_profit DESC;
