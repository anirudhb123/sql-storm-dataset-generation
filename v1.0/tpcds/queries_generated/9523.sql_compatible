
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_quarter_seq
), customer_summary AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer_demographics AS cd
    JOIN 
        web_sales AS ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
), return_summary AS (
    SELECT 
        cr_reason_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amt) AS total_returned_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_reason_sk
)

SELECT 
    ss.d_year,
    ss.d_month_seq,
    ss.d_quarter_seq,
    ss.total_net_profit,
    ss.total_orders,
    ss.unique_customers,
    cs.cd_gender,
    cs.total_quantity,
    cs.avg_net_profit,
    rs.total_returned_quantity,
    rs.total_returned_amount
FROM 
    sales_summary AS ss
JOIN 
    customer_summary AS cs ON cs.total_quantity > 10
LEFT JOIN 
    return_summary AS rs ON rs.total_returned_quantity > 0
WHERE 
    ss.total_net_profit > 5000
ORDER BY 
    ss.d_year, ss.d_month_seq, cs.cd_gender;
