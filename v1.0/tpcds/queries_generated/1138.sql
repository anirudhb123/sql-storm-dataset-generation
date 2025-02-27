
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders_by_customer
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_buy_potential
),
ranked_sales AS (
    SELECT 
        sd.web_site_id,
        sd.total_quantity,
        sd.total_net_profit,
        DENSE_RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (ORDER BY sd.total_quantity DESC) AS quantity_rank
    FROM 
        sales_data sd
)
SELECT 
    r.web_site_id,
    r.total_quantity,
    r.total_net_profit,
    c.c_customer_id,
    c.cd_gender,
    c.cd_marital_status,
    COALESCE(c.hd_income_band_sk, -1) AS income_band,
    COALESCE(c.hd_buy_potential, 'Unknown') AS buy_potential,
    r.profit_rank,
    r.quantity_rank
FROM 
    ranked_sales r
LEFT JOIN 
    customer_data c ON c.total_orders_by_customer > 5
WHERE 
    r.total_net_profit > (SELECT AVG(total_net_profit) FROM ranked_sales) 
ORDER BY 
    r.total_net_profit DESC, r.total_quantity DESC;
