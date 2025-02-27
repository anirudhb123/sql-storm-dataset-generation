
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
), 
item_ranking AS (
    SELECT 
        ss.ws_item_sk,
        i.i_product_name,
        ABS(i.i_current_price - COALESCE(s.total_net_profit, 0)) AS price_difference
    FROM 
        item i
    LEFT JOIN 
        sales_summary s ON i.i_item_sk = s.ws_item_sk
), 
customer_incomes AS (
    SELECT 
        h.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT c.c_customer_sk) AS counting_cust
    FROM 
        household_demographics h
    JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        h.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
) 
SELECT 
    c.c_customer_sk,
    c.total_spent,
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    ir.i_product_name,
    ir.price_difference
FROM 
    customer_summary c
JOIN 
    customer_incomes ci ON c.c_current_cdemo_sk = ci.hd_demo_sk
JOIN 
    item_ranking ir ON ir.ws_item_sk = (SELECT ss.ws_item_sk FROM sales_summary ss WHERE ss.profit_rank = 1)
WHERE 
    c.total_spent > 1000
ORDER BY 
    c.total_spent DESC
LIMIT 10;
