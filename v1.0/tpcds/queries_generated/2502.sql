
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
returned_sales AS (
    SELECT 
        wr.wr_web_page_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_value
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_web_page_sk
),
combined_sales AS (
    SELECT 
        ss.web_site_id,
        ss.total_net_profit,
        ss.total_orders,
        ss.avg_order_value,
        ss.unique_customers,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value,
        (ss.total_net_profit - COALESCE(rs.total_return_value, 0)) AS net_profit_after_returns
    FROM 
        sales_summary ss
    LEFT JOIN 
        returned_sales rs ON ss.web_site_id = rs.wr_web_page_sk
)
SELECT 
    web_site_id,
    total_net_profit,
    total_orders,
    avg_order_value,
    unique_customers,
    total_returns,
    total_return_value,
    net_profit_after_returns,
    RANK() OVER (ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM 
    combined_sales
WHERE 
    net_profit_after_returns > 0
ORDER BY 
    net_profit_after_returns DESC;
