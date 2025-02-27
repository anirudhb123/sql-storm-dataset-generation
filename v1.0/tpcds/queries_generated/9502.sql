
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        wd.d_year,
        wd.d_month_seq
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS wd ON ws.ws_sold_date_sk = wd.d_date_sk
    WHERE 
        wd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.web_site_id, wd.d_year, wd.d_month_seq
),
CustomerInsights AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales_by_customer
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_ext_sales_price) > 500
),
WarehouseReturns AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        warehouse AS w
    JOIN 
        store_returns AS sr ON w.w_warehouse_sk = sr.sr_store_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.avg_net_profit,
    ci.cd_gender,
    ci.cd_marital_status,
    wr.w_warehouse_id,
    wr.total_returns,
    wr.total_return_amount
FROM 
    SalesData AS sd
JOIN 
    CustomerInsights AS ci ON ci.total_sales_by_customer > 1000
JOIN 
    WarehouseReturns AS wr ON wr.total_returns > 0
ORDER BY 
    sd.total_sales DESC, wr.total_return_amount DESC
LIMIT 100;
