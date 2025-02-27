
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq IN (1, 2, 3) 
    GROUP BY 
        w.w_warehouse_id
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(ws.ws_order_number) AS orders_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT ws_sold_date_sk FROM web_sales)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
ItemSales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    WHERE 
        s.s_state = 'CA' AND ws.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        i.i_item_id, i.i_item_desc
)
SELECT 
    r.w_warehouse_id,
    r.total_sales,
    r.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    i.i_item_id,
    i.i_item_desc,
    i.total_quantity_sold,
    i.total_revenue
FROM 
    RankedSales r
JOIN 
    CustomerDemographics cd ON cd.orders_count > 0
JOIN 
    ItemSales i ON i.total_quantity_sold > 0
WHERE 
    r.sales_rank <= 3
ORDER BY 
    r.total_sales DESC, 
    i.total_revenue DESC;
