
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_purchase_estimate > 500
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.total_orders,
        c.total_profit,
        RANK() OVER (ORDER BY c.total_profit DESC) AS rank
    FROM 
        CustomerStats c
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_profit,
    wf.wf_warehouse_name,
    st.s_store_name,
    sm.sm_type
FROM 
    TopCustomers tc
JOIN 
    store_sales ss ON tc.c_customer_sk = ss.ss_customer_sk
JOIN 
    store st ON ss.ss_store_sk = st.s_store_sk
JOIN 
    warehouse wf ON st.s_store_sk = wf.w_warehouse_sk
JOIN 
    ship_mode sm ON ss.ss_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_profit DESC;
