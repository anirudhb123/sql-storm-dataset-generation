
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy IN (10, 11) 
    GROUP BY 
        cs.cs_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_age
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RankedSales AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_paid DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.cs_item_sk,
    rs.total_quantity,
    rs.total_net_paid,
    ci.cd_gender,
    ci.cd_age
FROM 
    RankedSales rs
JOIN 
    CustomerInfo ci ON ci.c_customer_sk IN (
        SELECT 
            DISTINCT cs.cs_bill_customer_sk 
        FROM 
            catalog_sales cs
        WHERE 
            cs.cs_item_sk = rs.cs_item_sk
    )
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.total_net_paid DESC;
