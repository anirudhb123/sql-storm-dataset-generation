
WITH sales_data AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ship_customer_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        COUNT(DISTINCT ws.web_page_sk) AS unique_pages_accessed
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND c.c_birth_year BETWEEN 1980 AND 1990
        AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.bill_customer_sk, ws.ship_customer_sk
), return_data AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.net_loss) AS total_return_loss
    FROM 
        web_returns wr
    WHERE 
        wr.returning_customer_sk IN (SELECT DISTINCT ship_customer_sk FROM sales_data)
    GROUP BY 
        wr.returning_customer_sk
)
SELECT 
    sd.bill_customer_sk,
    sd.total_profit,
    rd.total_return_loss,
    sd.total_orders,
    sd.unique_pages_accessed
FROM 
    sales_data sd
LEFT JOIN 
    return_data rd ON sd.ship_customer_sk = rd.returning_customer_sk
ORDER BY 
    sd.total_profit DESC
LIMIT 100;
