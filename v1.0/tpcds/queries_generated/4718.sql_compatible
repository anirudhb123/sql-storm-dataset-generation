
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.w_warehouse_name, d.d_year
),
customer_return_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns AS sr
    JOIN 
        customer AS c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
promo_analysis AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        promotion AS p
    JOIN 
        web_sales AS ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
),
income_bracket AS (
    SELECT 
        hd.hd_income_band_sk,
        AVG(hd.hd_buy_potential) AS avg_buy_potential
    FROM 
        household_demographics AS hd
    GROUP BY 
        hd.hd_income_band_sk
)

SELECT 
    ss.w_warehouse_name,
    ss.d_year,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_net_profit,
    crs.c_customer_id,
    crs.total_returns,
    crs.total_return_amt,
    pa.p_promo_name,
    pa.total_orders,
    pa.total_net_profit,
    ib.avg_buy_potential
FROM 
    sales_summary AS ss
LEFT JOIN 
    customer_return_summary AS crs ON crs.total_returns > 0
LEFT JOIN 
    promo_analysis AS pa ON pa.total_orders > 0
LEFT JOIN 
    income_bracket AS ib ON ib.avg_buy_potential IS NOT NULL
WHERE 
    ss.total_sales > 1000 
    OR crs.total_return_amt IS NOT NULL
ORDER BY 
    ss.d_year DESC, ss.total_sales DESC;
