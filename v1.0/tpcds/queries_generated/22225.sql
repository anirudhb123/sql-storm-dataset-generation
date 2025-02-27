
WITH RecursiveSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
SalesWithDemographics AS (
    SELECT 
        rs.c_customer_sk,
        rs.c_first_name,
        rs.c_last_name,
        rs.ws_sold_date_sk,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS estimated_purchase,
        DENSE_RANK() OVER (PARTITION BY rs.c_customer_sk ORDER BY rs.ws_net_paid DESC) AS net_paid_rank
    FROM 
        RecursiveSales rs
    LEFT JOIN 
        customer_demographics cd ON rs.c_customer_sk = cd.cd_demo_sk
),
SalesAggregate AS (
    SELECT 
        swd.c_customer_sk,
        COUNT(*) AS total_purchases,
        SUM(swd.ws_net_paid) AS total_spent,
        AVG(swd.ws_net_paid) AS avg_spent_per_purchase,
        MAX(swd.ws_net_paid) AS max_spent_on_single_purchase,
        SUM(CASE WHEN swd.ws_quantity > 5 THEN swd.ws_quantity ELSE 0 END) AS quantity_above_threshold
    FROM 
        SalesWithDemographics swd
    WHERE 
        swd.ws_net_paid IS NOT NULL
    GROUP BY 
        swd.c_customer_sk
)
SELECT 
    sa.c_customer_sk,
    ca.ca_city,
    ca.ca_state,
    sa.total_purchases,
    sa.total_spent,
    sa.avg_spent_per_purchase,
    sa.max_spent_on_single_purchase,
    sa.quantity_above_threshold,
    CASE 
        WHEN sa.avg_spent_per_purchase > 100 THEN 'High Roller'
        WHEN sa.avg_spent_per_purchase BETWEEN 50 AND 100 THEN 'Moderate Spender'
        ELSE 'Budget Buyer'
    END AS customer_category,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_purchased
FROM 
    SalesAggregate sa
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT ca_sk FROM customer WHERE c_customer_sk = sa.c_customer_sk)
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = sa.c_customer_sk
GROUP BY 
    sa.c_customer_sk, ca.ca_city, ca.ca_state, sa.total_purchases, sa.total_spent, sa.avg_spent_per_purchase, sa.max_spent_on_single_purchase, sa.quantity_above_threshold
HAVING 
    SUM(sa.total_spent) > 1000 OR COUNT(*) > 10
ORDER BY 
    total_spent DESC;
