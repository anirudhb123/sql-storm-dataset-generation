
WITH sales_data AS (
    SELECT 
        w.warehouse_name,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458720 AND 2458740  -- date range filter
    GROUP BY 
        w.warehouse_name, i.i_item_id, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
)
SELECT 
    warehouse_name,
    i_item_id,
    total_quantity,
    total_sales,
    avg_net_profit,
    CASE 
        WHEN hd_income_band_sk IS NULL THEN 'Unknown'
        WHEN hd_income_band_sk BETWEEN 1 AND 5 THEN 'Low Income'
        WHEN hd_income_band_sk BETWEEN 6 AND 10 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_band,
    cd_gender,
    cd_marital_status,
    RANK() OVER (PARTITION BY warehouse_name ORDER BY total_sales DESC) AS sales_rank
FROM 
    sales_data
WHERE 
    total_quantity > 100
ORDER BY 
    warehouse_name, sales_rank;
