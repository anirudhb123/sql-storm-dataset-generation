
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
TotalSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS TotalSalesAmount
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS CustomerCount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    'Best Selling Items' AS Category,
    r.ws_order_number,
    r.ws_ext_sales_price,
    COALESCE(ts.TotalSalesAmount, 0) AS TotalSalesByWarehouse,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.CustomerCount
FROM 
    RankedSales r
LEFT JOIN 
    TotalSales ts ON ts.w_warehouse_id = (SELECT w.w_warehouse_id FROM warehouse w LIMIT 1) 
LEFT JOIN 
    CustomerDemographics cd ON 1=1
WHERE 
    r.SalesRank <= 10
ORDER BY 
    r.ws_ext_sales_price DESC;
