
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
    AND 
        (cd.cd_gender = 'M' OR cd.cd_gender = 'F')
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rc.ca_city,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        customer c ON rc.c_customer_id = c.c_customer_id
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        rc.rn <= 5
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, rc.ca_city
),
CustomerHistory AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS unique_ship_dates
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
OrderDetails AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.ca_city,
    ch.total_orders,
    ch.unique_ship_dates,
    od.total_quantity,
    od.total_profit
FROM 
    TopCustomers tc
JOIN 
    CustomerHistory ch ON tc.c_customer_id = ch.c_customer_id
LEFT JOIN 
    OrderDetails od ON od.ws_order_number IN (SELECT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_id)
WHERE 
    (ch.total_orders > 0 AND ch.unique_ship_dates IS NOT NULL)
OR 
    (ch.total_orders = 0 AND tc.ca_city IS NOT NULL)
ORDER BY 
    total_profit DESC, tc.ca_city ASC;
