
WITH RECURSIVE revenue_ranking AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
return_summary AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns, 
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk 
                                 FROM date_dim 
                                 WHERE d_year = (SELECT MAX(d_year) FROM date_dim))
    GROUP BY 
        sr_item_sk
),
customer_segment AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
sales_by_category AS (
    SELECT 
        i_category_id, 
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    JOIN 
        item ON web_sales.ws_item_sk = item.i_item_sk
    WHERE 
        item.i_rec_start_date <= CURRENT_DATE AND 
        (item.i_rec_end_date IS NULL OR item.i_rec_end_date > CURRENT_DATE)
    GROUP BY 
        i_category_id
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.order_count,
    cs.total_spent,
    COALESCE(rr.total_profit, 0) AS total_profit_from_web,
    COALESCE(rs.total_returns, 0) AS total_returns,
    sbc.total_sales AS sales_per_category,
    sbc.avg_profit AS average_profit_per_category
FROM 
    customer_segment cs
LEFT JOIN 
    revenue_ranking rr ON cs.order_count > 0 AND rr.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_net_profit > 0)
LEFT JOIN 
    return_summary rs ON rs.sr_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cs.c_customer_sk)
LEFT JOIN 
    sales_by_category sbc ON cs.cd_income_band_sk = sbc.i_category_id
WHERE 
    (cs.order_count BETWEEN 1 AND 10 OR cs.total_spent > 1000)
ORDER BY 
    cs.total_spent DESC, cs.cd_gender, cs.cd_marital_status;
