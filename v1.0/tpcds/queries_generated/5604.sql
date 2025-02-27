
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS Total_Sales,
        COUNT(ws.ws_order_number) AS Total_Orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS Sales_Rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT cs.cs_order_number) AS Orders_Made
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
)
SELECT 
    r.web_site_id,
    r.Total_Sales,
    r.Total_Orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.Orders_Made
FROM 
    RankedSales r
JOIN 
    CustomerDemographics cd ON r.Total_Orders > cd.Orders_Made
WHERE 
    r.Sales_Rank <= 10
ORDER BY 
    r.Total_Sales DESC, cd.cd_gender;
