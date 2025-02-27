
WITH CustomerData AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        ARRAY_AGG(DISTINCT p.p_promo_name || ' (' || p.p_promo_id || ')') as promotions,
        COUNT(DISTINCT cs.cs_order_number) as total_orders,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
),
RankedCustomers AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) as profit_rank
    FROM 
        CustomerData
)
SELECT 
    first_name,
    last_name,
    city,
    state,
    gender,
    promotions,
    total_orders,
    total_profit,
    profit_rank
FROM 
    RankedCustomers
WHERE 
    profit_rank <= 10
ORDER BY 
    gender, total_profit DESC;
