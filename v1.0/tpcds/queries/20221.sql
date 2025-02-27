
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
        AND (c.c_preferred_cust_flag = 'Y' OR c.c_email_address IS NOT NULL)
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        ccs.c_customer_id,
        ccs.total_profit,
        ROW_NUMBER() OVER (ORDER BY ccs.total_profit DESC) AS rank
    FROM 
        CustomerSales ccs
    WHERE 
        ccs.total_profit IS NOT NULL
),
DateStats AS (
    SELECT 
        d.d_year,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
),
StoreSalesComparison AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(ss.ss_ticket_number) AS total_tickets
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        (s.s_market_desc LIKE '%Urban%' OR s.s_floor_space > 5000)
        AND s.s_tax_precentage IS NOT NULL
    GROUP BY 
        s.s_store_id
)
SELECT 
    tc.c_customer_id,
    tc.total_profit,
    ds.avg_net_paid,
    ss.total_store_profit,
    (CASE 
        WHEN ss.total_tickets > 100 THEN 'High Activity'
        WHEN ss.total_tickets BETWEEN 50 AND 100 THEN 'Medium Activity'
        ELSE 'Low Activity' 
    END) AS store_activity_level
FROM 
    TopCustomers tc
JOIN 
    DateStats ds ON ds.d_year = 2021
JOIN 
    StoreSalesComparison ss ON ss.total_store_profit = 
    (SELECT MAX(total_store_profit) FROM StoreSalesComparison)
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_profit DESC
LIMIT 5
OFFSET (SELECT COUNT(*) FROM TopCustomers) / 2;
