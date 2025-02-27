
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > 1000 
        AND cd.cd_gender = 'F'
), 
RankedSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.avg_order_value,
        RANK() OVER(PARTITION BY cs.order_count ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_id = cd.cd_demo_sk
)
SELECT 
    rs.c_customer_id,
    rs.total_sales,
    rs.order_count,
    rs.avg_order_value,
    rs.sales_rank,
    COALESCE(d.d_day_name, 'Unknown') AS sale_day,
    CASE 
        WHEN d.d_today = 'Y' THEN 'Today'
        ELSE 'Not Today'
    END AS is_today
FROM 
    RankedSales rs
LEFT JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_day = 'Y')
WHERE 
    rs.order_count > 5
ORDER BY 
    rs.total_sales DESC
LIMIT 100;
