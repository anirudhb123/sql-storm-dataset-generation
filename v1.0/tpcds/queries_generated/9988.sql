
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit_per_order
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
DemographicDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        chd.hd_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics chd ON cd.cd_demo_sk = chd.hd_demo_sk
),
RankedCustomerSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.total_orders,
        cs.avg_profit_per_order,
        dm.cd_gender,
        dm.cd_marital_status,
        RANK() OVER (PARTITION BY dm.cd_gender ORDER BY cs.total_spent DESC) AS gender_rank,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS overall_rank
    FROM 
        CustomerSales cs
    JOIN 
        DemographicDetails dm ON cs.c_customer_id = dm.cd_demo_sk
)
SELECT 
    rcs.c_customer_id,
    rcs.total_spent,
    rcs.total_orders,
    rcs.avg_profit_per_order,
    rcs.cd_gender,
    rcs.cd_marital_status,
    rcs.gender_rank,
    rcs.overall_rank
FROM 
    RankedCustomerSales rcs
WHERE 
    rcs.gender_rank <= 10 OR rcs.overall_rank <= 10
ORDER BY 
    rcs.total_spent DESC;
