
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20221231
),

CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state,
        ca.ca_city
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),

SalesSummary AS (
    SELECT 
        cs.bill_customer_sk,
        SUM(cs.net_paid) AS total_spent,
        COUNT(DISTINCT cs.order_number) AS total_orders
    FROM 
        store_sales cs
    GROUP BY 
        cs.bill_customer_sk
),

ReturnStats AS (
    SELECT 
        sr.returning_customer_sk,
        COUNT(sr.return_order_number) AS total_returns,
        SUM(sr.return_amt) AS total_returned
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        sr.returning_customer_sk
)

SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ca_state,
    cd.ca_city,
    COALESCE(SUM(r.total_spent), 0) AS total_spent_last_year,
    COALESCE(SUM(r.total_orders), 0) AS total_orders_last_year,
    COALESCE(SUM(rs.total_returns), 0) AS total_returns_last_year,
    COUNT(DISTINCT CASE WHEN rs.total_returns > 0 THEN rs.returning_customer_sk END) AS returning_customers,
    MAX(CASE WHEN rs.total_returned IS NULL THEN 0 ELSE rs.total_returned END) AS max_returned_amt
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesSummary r ON cd.c_customer_sk = r.bill_customer_sk
LEFT JOIN 
    ReturnStats rs ON cd.c_customer_sk = rs.returning_customer_sk
GROUP BY 
    cd.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.ca_state, cd.ca_city
HAVING 
    AVG(COALESCE(r.total_spent, 0)) < 1000 AND
    COUNT(DISTINCT r.total_orders) > 0
ORDER BY 
    total_spent_last_year DESC, cd.cd_gender, cd.cd_marital_status;
