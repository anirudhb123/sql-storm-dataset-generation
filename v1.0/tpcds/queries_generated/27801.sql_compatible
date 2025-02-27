
WITH CustomerDemographics AS (
    SELECT 
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.purchase_estimate,
        cd.credit_rating,
        cd.dep_count,
        ca.city,
        ca.state,
        ca.country
    FROM 
        customer_demographics cd
    JOIN 
        customer_address ca ON cd.demo_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.item_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_sales,
        SUM(ws.ext_discount_amt) AS total_discounts
    FROM 
        web_sales ws
    JOIN 
        CustomerDemographics cd ON ws.bill_customer_sk = cd.demo_sk
    WHERE 
        cd.purchase_estimate > 1000
    GROUP BY 
        ws.item_sk
),
SalesRanked AS (
    SELECT 
        item_sk,
        total_orders,
        total_sales,
        total_discounts,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    ir.item_desc, 
    sr.total_orders, 
    sr.total_sales, 
    sr.total_discounts,
    sr.sales_rank
FROM 
    SalesRanked sr
JOIN 
    item ir ON sr.item_sk = ir.i_item_sk
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.sales_rank;
