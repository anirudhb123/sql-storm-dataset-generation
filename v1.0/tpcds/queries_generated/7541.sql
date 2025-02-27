
WITH SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(ws.order_number) AS total_orders,
        AVG(ws.net_profit) AS avg_profit,
        DATEDIFF(DAY, MIN(d.d_date), MAX(d.d_date)) AS sales_duration
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.bill_customer_sk
), CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), RankedSales AS (
    SELECT 
        sd.bill_customer_sk,
        sd.total_sales,
        sd.total_orders,
        sd.avg_profit,
        sd.sales_duration,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.bill_customer_sk = cd.c_customer_sk
)
SELECT 
    rs.sales_rank,
    rs.c_first_name,
    rs.c_last_name,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.total_sales,
    rs.total_orders,
    rs.avg_profit,
    rs.sales_duration
FROM 
    RankedSales rs
WHERE 
    rs.total_sales > (SELECT AVG(total_sales) FROM SalesData)
ORDER BY 
    rs.total_sales DESC
LIMIT 50;
