
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_salutation
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesOverview AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
YearlySales AS (
    SELECT 
        dd.d_year,
        SUM(ws.ws_net_profit) AS yearly_profit
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_year
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip,
    COALESCE(so.total_profit, 0) AS total_profit,
    COALESCE(so.total_orders, 0) AS total_orders,
    COALESCE(so.distinct_items_sold, 0) AS distinct_items_sold,
    ys.d_year,
    ys.yearly_profit
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesOverview so ON cd.c_customer_sk = so.ws_bill_customer_sk
LEFT JOIN 
    YearlySales ys ON cd.c_customer_sk IN (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = cd.c_customer_sk)
WHERE 
    cd.ca_state = 'CA'
ORDER BY 
    cd.full_name ASC, ys.d_year DESC;
