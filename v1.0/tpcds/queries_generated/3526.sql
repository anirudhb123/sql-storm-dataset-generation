
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        cs.order_count,
        cs.last_purchase_date,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_net_profit > (SELECT AVG(total_net_profit) FROM CustomerSales)
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_net_profit,
    hvc.order_count,
    CASE 
        WHEN hvc.last_purchase_date IS NOT NULL THEN 'Active'
        ELSE 'Inactive' 
    END AS customer_status,
    DATEDIFF(CURRENT_DATE, TO_DATE(DATE_FROM_UNIX_TIMESTAMP(hvc.last_purchase_date))) AS days_since_last_purchase
FROM 
    HighValueCustomers hvc
WHERE 
    hvc.rank <= 10 
ORDER BY 
    hvc.total_net_profit DESC;

SELECT 
    DISTINCT ca.ca_county, 
    SUM(ws.ws_net_paid_inc_tax) AS total_sales
FROM 
    customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' AND 
    ws.ws_net_paid_inc_tax IS NOT NULL
GROUP BY 
    ca.ca_county
HAVING 
    total_sales > (
        SELECT AVG(total_sales) 
        FROM (
            SELECT SUM(ws2.ws_net_paid_inc_tax) AS total_sales
            FROM customer_address ca2
            JOIN customer c2 ON ca2.ca_address_sk = c2.c_current_addr_sk
            JOIN web_sales ws2 ON c2.c_customer_sk = ws2.ws_bill_customer_sk
            GROUP BY ca2.ca_county
        ) AS county_sales
    )
ORDER BY 
    total_sales DESC
LIMIT 10;
