
WITH SalesData AS (
    SELECT 
        d.d_year, 
        w.w_warehouse_id, 
        SUM(ws.ws_net_paid) AS total_sales, 
        AVG(ws.ws_sales_price) AS avg_price, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, w.w_warehouse_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(sd.total_sales) AS sales_by_demo
    FROM 
        SalesData sd
    JOIN 
        customer c ON c.c_customer_sk = sd.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.sales_by_demo, 
    RANK() OVER (ORDER BY cd.sales_by_demo DESC) AS sales_rank
FROM 
    CustomerDemographics cd
WHERE 
    cd.sales_by_demo > 100000
ORDER BY 
    cd.sales_rank;
