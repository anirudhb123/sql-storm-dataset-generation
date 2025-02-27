
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
RecentReturns AS (
    SELECT 
        sr.returning_customer_sk,
        SUM(sr.return_quantity) AS total_returned_items
    FROM 
        store_returns AS sr
    WHERE 
        sr.sr_returned_date_sk = (
            SELECT MAX(sr_inner.sr_returned_date_sk) 
            FROM store_returns AS sr_inner 
            WHERE sr_inner.returning_customer_sk = sr.returning_customer_sk
        )
    GROUP BY 
        sr.returning_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(rr.total_returned_items, 0) AS total_returned_items,
    COALESCE(sd.total_profit, 0) AS total_profit,
    COALESCE(sd.total_orders, 0) AS total_orders
FROM 
    CustomerInfo AS ci
LEFT JOIN 
    RecentReturns AS rr ON ci.c_customer_sk = rr.returning_customer_sk
LEFT JOIN 
    SalesData AS sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ci.rank = 1
    AND (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
ORDER BY 
    total_profit DESC, 
    ci.c_last_name ASC;
