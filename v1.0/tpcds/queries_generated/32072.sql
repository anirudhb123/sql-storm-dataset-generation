
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_dow = 5  -- Consider only Fridays
    GROUP BY 
        ws.web_site_sk
), order_counts AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
), customer_stats AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(wr.wr_return_amount, 0)) AS total_returned_amt,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
), influential_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_returned_amt,
        RANK() OVER (ORDER BY cs.total_returned_amt DESC) AS customer_rank
    FROM 
        customer_stats cs
    WHERE 
        cs.total_returned_amt > 1000  -- Only consider customers with significant returns
)
SELECT 
    sd.web_site_sk,
    sd.total_net_profit,
    oc.order_count,
    ic.customer_rank
FROM 
    sales_data sd
JOIN 
    order_counts oc ON sd.web_site_sk = oc.web_site_sk
LEFT JOIN 
    influential_customers ic ON sd.web_site_sk = ic.c_customer_sk
WHERE 
    sd.rn <= 10  -- Top 10 websites by profit
ORDER BY 
    sd.total_net_profit DESC;
