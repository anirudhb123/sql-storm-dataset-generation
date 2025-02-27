
WITH RECURSIVE SalesCTE AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales 
    GROUP BY 
        s_store_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_web_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_credit_rating, ca.ca_state
),
TopCustomers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_web_sales DESC) AS state_rank
    FROM 
        CustomerData
    WHERE 
        total_web_sales > 0
)
SELECT 
    a.s_store_sk,
    a.total_net_profit,
    b.c_first_name,
    b.c_last_name,
    b.cd_gender,
    b.cd_credit_rating,
    b.ca_state
FROM 
    SalesCTE a
JOIN 
    TopCustomers b ON a.s_store_sk = b.c_customer_sk
WHERE 
    a.rank <= 10 
    AND b.state_rank <= 5
ORDER BY 
    a.total_net_profit DESC, 
    b.total_web_sales DESC;
