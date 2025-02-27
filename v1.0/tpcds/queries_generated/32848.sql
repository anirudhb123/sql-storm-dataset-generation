
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS num_orders,
        ROW_NUMBER() OVER(PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_sales,
        ss.num_orders,
        ROW_NUMBER() OVER(ORDER BY ss.total_sales DESC) AS customer_rank
    FROM 
        customer AS cs
    JOIN 
        sales_summary AS ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.rank <= 10
),
high_income_customers AS (
    SELECT 
        h.hd_demo_sk,
        h.hd_income_band_sk,
        h.hd_buy_potential,
        SUM(wh.ws_net_profit) AS total_net_profit
    FROM 
        household_demographics AS h
    JOIN 
        web_sales AS wh ON h.hd_demo_sk = wh.ws_bill_cdemo_sk
    WHERE 
        h.hd_income_band_sk IS NOT NULL 
    GROUP BY 
        h.hd_demo_sk, h.hd_income_band_sk, h.hd_buy_potential
),
customer_returns AS (
    SELECT 
        sr.refunded_customer_sk,
        SUM(sr.return_amt_inc_tax) AS total_returns
    FROM 
        store_returns AS sr
    GROUP BY 
        sr.refunded_customer_sk
)

SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.num_orders,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(hi.total_net_profit, 0) AS high_income_net_profit,
    CASE 
        WHEN tc.total_sales > COALESCE(cr.total_returns, 0) THEN 'Profit'
        ELSE 'Loss'
    END AS profitability_status
FROM 
    top_customers AS tc
LEFT JOIN 
    customer_returns AS cr ON tc.c_customer_sk = cr.refunded_customer_sk
LEFT JOIN 
    high_income_customers AS hi ON tc.c_customer_sk = hi.hd_demo_sk
WHERE 
    tc.customer_rank <= 5
ORDER BY 
    tc.total_sales DESC;
