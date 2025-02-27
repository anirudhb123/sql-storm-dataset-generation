
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
HighValueItems AS (
    SELECT 
        ir.i_item_id,
        SUM(ir.sales) AS total_sales,
        MAX(ir.profit) AS max_profit
    FROM (
        SELECT
            ws.ws_item_sk,
            i.i_item_id,
            ws.ws_ext_sales_price AS sales,
            ws.ws_net_profit AS profit
        FROM
            web_sales ws
        JOIN 
            item i ON ws.ws_item_sk = i.i_item_sk
        WHERE 
            ws.ws_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-06-01')
    ) ir
    GROUP BY 
        ir.i_item_id
    HAVING 
        SUM(ir.sales) > 10000
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    hi.i_item_id,
    hi.total_sales,
    hi.max_profit
FROM 
    CustomerData c
JOIN 
    HighValueItems hi ON c.total_orders > 5
LEFT JOIN 
    customer_demographics cd ON c.cd_income_band_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F'
    AND hi.total_sales IS NOT NULL
ORDER BY 
    hi.total_sales DESC, 
    c.c_customer_id
FETCH FIRST 100 ROWS ONLY;
