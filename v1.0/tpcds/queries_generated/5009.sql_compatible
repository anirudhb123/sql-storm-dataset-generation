
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        COUNT(ws.item_sk) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws 
    JOIN 
        customer_address ca ON ws.bill_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON ws.bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND ca.ca_country = 'USA'
        AND ws.sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.bill_customer_sk
),
TopCustomers AS (
    SELECT 
        bill_customer_sk,
        total_net_profit,
        total_orders,
        total_items
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    tc.total_net_profit,
    tc.total_orders,
    tc.total_items,
    ca.city,
    ca.state
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    tc.total_net_profit DESC;
