
WITH RankedSales AS (
    SELECT 
        w.warehouse_id,
        s.store_name,
        ws.web_site_id,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY w.warehouse_id ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    JOIN 
        store s ON ws.warehouse_sk = s.warehouse_sk
    GROUP BY 
        w.warehouse_id, s.store_name, ws.web_site_id
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.net_profit) AS customer_profit,
        COUNT(DISTINCT ws.order_number) AS order_count
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.customer_profit,
        ROW_NUMBER() OVER (ORDER BY cs.customer_profit DESC) AS customer_rank
    FROM 
        CustomerStats cs
)
SELECT 
    rs.warehouse_id,
    rs.store_name,
    rs.web_site_id,
    rs.total_profit,
    tc.c_customer_id,
    tc.customer_profit
FROM 
    RankedSales rs
JOIN 
    TopCustomers tc ON rs.total_profit > 0
WHERE 
    rs.profit_rank <= 5 AND tc.customer_rank <= 10
ORDER BY 
    rs.total_profit DESC, tc.customer_profit DESC;
