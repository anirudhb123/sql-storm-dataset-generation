
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
CustomerAnalysis AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(sd.total_sales) AS total_sales_by_gender,
        SUM(sd.total_orders) AS total_orders_by_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON sd.unique_customers = COUNT(DISTINCT c.c_customer_sk)
    GROUP BY 
        cd.cd_gender
),
DateAnalysis AS (
    SELECT 
        d.d_year,
        SUM(sd.total_sales) AS yearly_sales,
        SUM(sd.total_orders) AS yearly_orders,
        COUNT(DISTINCT sd.w_warehouse_id) AS active_warehouses
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        SalesData sd ON ws.ws_warehouse_sk = sd.w_warehouse_id
    GROUP BY 
        d.d_year
)
SELECT 
    da.d_year,
    da.yearly_sales,
    da.yearly_orders,
    ca.cd_gender,
    ca.customer_count,
    ca.total_sales_by_gender,
    ca.total_orders_by_gender
FROM 
    DateAnalysis da
JOIN 
    CustomerAnalysis ca ON ca.total_orders_by_gender > 0
ORDER BY 
    da.d_year DESC, ca.cd_gender;
