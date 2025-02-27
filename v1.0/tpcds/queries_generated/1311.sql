
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_profit) AS total_profit,
        AVG(s.ss_sales_price) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesDemographics AS (
    SELECT 
        cs.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cs.total_sales,
        cs.total_profit,
        cs.avg_sales_price
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
),
IncomeStats AS (
    SELECT 
        sd.cd_gender,
        sd.cd_marital_status,
        COUNT(sd.c_customer_id) AS customer_count,
        SUM(sd.total_sales) AS sum_sales,
        SUM(sd.total_profit) AS sum_profit,
        AVG(sd.avg_sales_price) AS avg_price
    FROM 
        SalesDemographics sd
    GROUP BY 
        sd.cd_gender, sd.cd_marital_status
),
RankedIncomeStats AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY sum_profit DESC) AS rank
    FROM 
        IncomeStats
)
SELECT 
    ri.cd_gender,
    ri.cd_marital_status,
    ri.customer_count,
    ri.sum_sales,
    ri.sum_profit,
    ri.avg_price,
    CASE 
        WHEN ri.rank = 1 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    RankedIncomeStats ri
WHERE 
    ri.customer_count > 10 
    AND ri.sum_sales > 5000
    AND ri.avg_price IS NOT NULL
ORDER BY 
    ri.sum_profit DESC;
