
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_sales_price) AS total_sales_price
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        cs.cs_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS warehouse_sales_quantity,
        SUM(ws.ws_net_profit) AS warehouse_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.cs_item_sk,
    sd.total_quantity,
    sd.total_net_profit,
    sd.total_discount,
    sd.total_sales_price,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.customer_count,
    ws.warehouse_sales_quantity,
    ws.warehouse_net_profit
FROM 
    SalesData sd
LEFT JOIN 
    CustomerData cd ON sd.cs_item_sk IN (
        SELECT  
            DISTINCT wr.wr_item_sk 
        FROM 
            web_returns wr 
        JOIN 
            customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    )
LEFT JOIN 
    WarehouseSales ws ON sd.cs_item_sk IN (
        SELECT 
            DISTINCT cs.cs_item_sk 
        FROM 
            catalog_sales cs 
        JOIN 
            web_sales ws ON cs.cs_item_sk = ws.ws_item_sk
    )
ORDER BY 
    sd.total_net_profit DESC
LIMIT 100;
