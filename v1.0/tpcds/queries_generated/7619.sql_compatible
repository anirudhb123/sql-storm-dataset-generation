
WITH CustomerReturns AS (
    SELECT 
        cu.c_customer_sk AS customer_id,
        cu.c_first_name,
        cu.c_last_name,
        COUNT(DISTINCT sr.return_ticket_number) AS total_store_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM 
        customer cu
    LEFT JOIN 
        store_returns sr ON cu.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        cu.c_customer_sk, cu.c_first_name, cu.c_last_name
),
PromotionDetails AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS total_sales_generated,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d)
        AND p.p_end_date_sk > (SELECT MIN(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
LastYearSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS last_year_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = (SELECT MAX(d_year) FROM date_dim) - 1
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    cr.customer_id,
    cr.c_first_name,
    cr.c_last_name,
    pd.p_promo_name,
    pd.total_sales_generated,
    lr.last_year_net_profit,
    cr.total_store_returns,
    cr.total_return_amount,
    cr.avg_return_quantity
FROM 
    CustomerReturns cr
LEFT JOIN 
    PromotionDetails pd ON cr.customer_id IN (SELECT ws_bill_customer_sk FROM web_sales ws)
LEFT JOIN 
    LastYearSales lr ON lr.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cr.customer_id)
WHERE 
    cr.total_store_returns > 0
ORDER BY 
    cr.total_return_amount DESC, pd.total_sales_generated DESC;
