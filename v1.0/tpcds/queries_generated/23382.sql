
WITH RankedSales AS (
    SELECT 
        ws.customer_sk,
        ws.order_number,
        ws.quantity,
        ws.net_paid,
        RANK() OVER (PARTITION BY ws.customer_sk ORDER BY ws.net_paid DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
),
CustomerDemoAggregate AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(cd.cd_dep_count) AS total_dependencies,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_credit_rating) AS min_credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'S'
    GROUP BY 
        cd.cd_demo_sk
),
JoinWithReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.ticket_number,
        sr.return_quantity,
        COALESCE(sr.return_amt, 0) AS return_amt,
        COALESCE(sr.return_tax, 0) AS return_tax
    FROM 
        store_returns sr
    LEFT JOIN 
        store s ON sr.store_sk = s.s_store_sk
    WHERE 
        s.s_state IS NOT NULL
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(COALESCE(ws.quantity, 0)) AS total_quantity_sold,
    COUNT(DISTINCT ws.order_number) AS distinct_orders,
    SUM(CASE WHEN ws.net_paid > 100 THEN 1 ELSE 0 END) AS high_value_orders,
    AVG(COALESCE(cr.return_amount, 0)) AS avg_return_amount,
    MAX(cd.total_dependencies) AS max_dependencies,
    DENSE_RANK() OVER (ORDER BY SUM(ws.net_paid) DESC) as revenue_rank
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
LEFT JOIN 
    JoinWithReturns cr ON ws.item_sk = cr.item_sk
LEFT JOIN 
    CustomerDemoAggregate cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.order_number) > 5
    AND MAX(cd.max_purchase_estimate) > 500
ORDER BY 
    total_quantity_sold DESC, ca.ca_city ASC;
