
WITH SalesSummary AS (
    SELECT 
        ws_product_info.item_id,
        ws_product_info.item_description,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item ws_product_info ON ws.ws_item_sk = ws_product_info.i_item_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
        AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status IN ('M', 'S'))
    GROUP BY 
        ws_product_info.item_id, ws_product_info.item_description, cd.cd_gender
), 
RankedSales AS (
    SELECT 
        item_id, 
        item_description, 
        total_quantity_sold,
        total_sales,
        total_orders,
        sales_rank,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS overall_rank
    FROM 
        SalesSummary
    WHERE 
        total_sales IS NOT NULL
)

SELECT 
    r.item_id,
    r.item_description,
    r.total_quantity_sold,
    r.total_sales,
    r.total_orders,
    r.sales_rank,
    r.overall_rank,
    CASE 
        WHEN r.total_sales > 100000 THEN 'High Performer'
        WHEN r.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Performer'
        ELSE 'Low Performer' 
    END AS performance_category,
    COALESCE(r.total_quantity_sold / NULLIF(r.total_orders, 0), 0) AS avg_quantity_per_order
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.overall_rank;
