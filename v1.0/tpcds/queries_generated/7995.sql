
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600  -- Approx date range
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_quantity,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON c.c_customer_id = cs.c_customer_id
    WHERE 
        cs.total_orders > 5
)
SELECT 
    tc.c_customer_id,
    tc.total_quantity,
    tc.total_profit,
    tc.profit_rank,
    cd.cd_gender,
    hd.hd_income_band_sk
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    tc.total_profit DESC;
