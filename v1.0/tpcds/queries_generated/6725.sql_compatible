
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value,
        MAX(ws.ws_net_paid_inc_tax) AS max_order_value,
        MIN(ws.ws_net_paid_inc_tax) AS min_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
        COUNT(DISTINCT CASE WHEN cd.cd_gender = 'F' THEN c.c_customer_id END) AS female_customers,
        COUNT(DISTINCT CASE WHEN cd.cd_gender = 'M' THEN c.c_customer_id END) AS male_customers
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
), 
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_orders,
        cs.total_spent,
        cs.average_order_value,
        cd.customer_count,
        cd.average_purchase_estimate,
        cd.female_customers,
        cd.male_customers
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_id = cd.c_customer_id
)
SELECT 
    s.c_customer_id,
    s.total_orders,
    s.total_spent,
    s.average_order_value,
    s.customer_count,
    s.average_purchase_estimate,
    s.female_customers,
    s.male_customers,
    RANK() OVER (ORDER BY s.total_spent DESC) AS rank_by_spent
FROM 
    SalesSummary s
WHERE 
    s.total_orders > 1
ORDER BY 
    s.total_spent DESC;
