
WITH SalesData AS (
    SELECT 
        w.warehouse_name,
        SUM(CASE WHEN ws_sold_date_sk BETWEEN 2451000 AND 2451120 THEN ws_quantity ELSE 0 END) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.warehouse_name
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        SUM(sd.total_quantity) AS total_sales_quantity,
        SUM(sd.total_profit) AS total_sales_profit,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON sd.warehouse_name = (
            SELECT w.warehouse_name 
            FROM warehouse w 
            WHERE w.warehouse_sk = c.c_current_addr_sk
        )
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.cd_gender,
    cd.total_sales_quantity,
    cd.total_sales_profit,
    cd.unique_customers,
    RANK() OVER (ORDER BY cd.total_sales_profit DESC) AS profit_rank
FROM 
    CustomerData cd
ORDER BY 
    cd.total_sales_profit DESC;
