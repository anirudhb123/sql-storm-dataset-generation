
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        LISTAGG(DISTINCT CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip), '; ') WITHIN GROUP (ORDER BY ca.ca_city) AS address_info
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)

SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_net_profit,
    cs.total_orders,
    cs.total_web_returns,
    COUNT(DISTINCT cs.address_info) AS unique_addresses
FROM 
    CustomerStats cs
WHERE 
    cs.total_net_profit > 1000
GROUP BY 
    cs.full_name, cs.cd_gender, cs.cd_marital_status, cs.cd_education_status, cs.total_net_profit, cs.total_orders, cs.total_web_returns
ORDER BY 
    cs.total_net_profit DESC;
