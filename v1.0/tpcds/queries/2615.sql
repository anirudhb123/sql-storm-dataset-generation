
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
)

SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    ti.total_profit,
    CASE 
        WHEN cd.customer_count IS NULL THEN 'No data' 
        ELSE CAST(cd.customer_count AS VARCHAR) 
    END AS customer_count,
    CASE 
        WHEN ti.total_profit > 1000 THEN 'High Profit'
        WHEN ti.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    TopItems ti
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = (
        SELECT cd_demo_sk 
        FROM customer c 
        WHERE c.c_current_cdemo_sk IS NOT NULL
        LIMIT 1
    )
ORDER BY 
    ti.total_sales DESC;
