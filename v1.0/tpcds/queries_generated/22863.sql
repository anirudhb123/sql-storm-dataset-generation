
WITH RECURSIVE Customer_CTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_marital_status,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
), 
Return_Summary AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_net_loss) AS avg_net_loss
    FROM 
        store_sales ss
    LEFT JOIN 
        store_returns sr ON ss.ss_item_sk = sr.sr_item_sk
    GROUP BY 
        ss.ss_store_sk
),
Sales_Data AS (
    SELECT 
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid_inc_tax > 0
    GROUP BY 
        ws.ws_ship_mode_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(s.total_profit) AS total_sales_profit,
    r.total_returns,
    r.total_return_amount,
    CASE 
        WHEN r.total_returns IS NULL THEN 'No Returns'
        ELSE 'Returns Made'
    END AS return_status,
    COUNT(DISTINCT c.customer_sk) AS returning_customers
FROM 
    customer_address ca
LEFT JOIN 
    Return_Summary r ON ca.ca_address_sk = r.ss_store_sk
JOIN 
    (SELECT c_customer_sk FROM Customer_CTE WHERE rn <= 5) c ON c.c_customer_sk = r.ss_store_sk
JOIN 
    Sales_Data s ON s.ws_ship_mode_sk = r.ss_store_sk
GROUP BY 
    ca.ca_city, ca.ca_state, r.total_returns
HAVING 
    SUM(s.total_profit) > (SELECT AVG(total_profit) FROM Sales_Data WHERE profit_rank <= 3)
    OR MAX(r.total_return_amount) IS NULL
ORDER BY 
    total_sales_profit DESC, return_status;
