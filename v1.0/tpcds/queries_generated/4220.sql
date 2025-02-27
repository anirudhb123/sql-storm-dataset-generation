
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS profit_rank
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_net_profit
    FROM 
        warehouse w
        LEFT JOIN store s ON w.w_warehouse_sk = s.s_store_sk
        LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
ReturnSummary AS (
    SELECT 
        sr.rc_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.rc_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_net_profit,
    cs.total_orders,
    ws.total_store_sales,
    ws.total_store_net_profit,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned_amount, 0) AS total_returned_amount
FROM 
    CustomerStats cs
    LEFT JOIN WarehouseStats ws ON cs.c_customer_sk = ws.w_warehouse_sk
    LEFT JOIN ReturnSummary rs ON cs.c_customer_sk = rs.rc_customer_sk
WHERE 
    cs.profit_rank <= 5
ORDER BY 
    cs.total_net_profit DESC;
