
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        MAX(ws.ws_net_paid_inc_tax) AS largest_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_spent) AS total_revenue
    FROM 
        customer_demographics cd
    LEFT JOIN 
        CustomerSales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
SalesByShippingMode AS (
    SELECT 
        sm.sm_ship_mode_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.total_revenue,
    sbs.sm_ship_mode_id,
    sbs.total_sales
FROM 
    CustomerDemographics cd
JOIN 
    SalesByShippingMode sbs ON cd.customer_count > 100
ORDER BY 
    cd.total_revenue DESC, 
    sbs.total_sales DESC
LIMIT 10;
