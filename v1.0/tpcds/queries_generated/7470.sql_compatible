
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
), CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS customer_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id, cd.cd_gender
), IncomeStats AS (
    SELECT 
        ib.ib_income_band_sk,
        AVG(hd.hd_dep_count) AS avg_dep_count,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        web_sales ws ON hd.hd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    rs.web_site_id,
    rs.total_orders,
    rs.total_net_profit,
    cs.cd_gender,
    cs.order_count,
    cs.customer_net_profit,
    is.ib_income_band_sk,
    is.avg_dep_count,
    is.total_net_paid
FROM 
    RankedSales rs
JOIN 
    CustomerStats cs ON rs.web_site_id = cs.c_customer_id
JOIN 
    IncomeStats is ON cs.order_count > 5
WHERE 
    rs.rank <= 10
ORDER BY 
    rs.total_net_profit DESC, cs.customer_net_profit DESC;
