
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(cs.total_sales) AS max_sales,
        AVG(cs.total_sales) AS avg_sales,
        SUM(cs.order_count) AS total_orders,
        SUM(cs.unique_items_purchased) AS total_unique_items
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
DemographicSummary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS customer_count,
        SUM(cd.total_orders) AS total_orders,
        AVG(cd.avg_sales) AS avg_sales_per_customer,
        MAX(cd.max_sales) AS highest_sales
    FROM 
        CustomerDemographics cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.total_orders,
    ds.avg_sales_per_customer,
    ds.highest_sales
FROM 
    DemographicSummary ds
ORDER BY 
    ds.cd_gender, ds.cd_marital_status;
