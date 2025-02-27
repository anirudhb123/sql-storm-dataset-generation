WITH RankedSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001
        AND dd.d_month_seq IN (1, 2, 3) 
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        rc.c_customer_id, 
        rc.total_net_profit, 
        rc.order_count
    FROM 
        RankedSales AS rc 
    WHERE 
        rc.profit_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.total_net_profit,
    tc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers AS tc
JOIN 
    customer_demographics AS cd ON cd.cd_demo_sk = (
        SELECT 
            c.c_current_cdemo_sk 
        FROM 
            customer AS c 
        WHERE 
            c.c_customer_id = tc.c_customer_id
    )
JOIN 
    customer_address AS ca ON ca.ca_address_sk = (
        SELECT 
            c.c_current_addr_sk 
        FROM 
            customer AS c 
        WHERE 
            c.c_customer_id = tc.c_customer_id
    )
ORDER BY 
    tc.total_net_profit DESC;