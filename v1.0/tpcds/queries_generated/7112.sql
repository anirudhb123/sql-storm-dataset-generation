
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        w.w_warehouse_name
), CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price) AS customer_total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), RankingData AS (
    SELECT 
        warehouse_name,
        total_quantity_sold,
        total_sales,
        total_net_profit,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        SalesData
)
SELECT 
    rd.warehouse_name,
    rd.total_quantity_sold,
    rd.total_sales,
    rd.total_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_total_sales
FROM 
    RankingData rd
JOIN 
    CustomerData cd ON rd.total_sales = cd.customer_total_sales
WHERE 
    rd.profit_rank <= 10
ORDER BY 
    rd.total_net_profit DESC, cd.customer_total_sales DESC;
