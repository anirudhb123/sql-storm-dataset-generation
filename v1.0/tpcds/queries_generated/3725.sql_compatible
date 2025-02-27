
WITH SalesStats AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'S'
    GROUP BY 
        ws.web_site_id
),
ItemStats AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        i.i_item_id, i.i_product_name
),
HighValueItems AS (
    SELECT 
        item_stats.i_item_id,
        item_stats.i_product_name,
        item_stats.order_count,
        item_stats.total_quantity_sold,
        item_stats.avg_sales_price,
        ss.total_sales
    FROM 
        ItemStats item_stats
    JOIN 
        SalesStats ss ON item_stats.order_count > 10
    WHERE 
        item_stats.total_quantity_sold >= 100
),
FinalResults AS (
    SELECT 
        hvi.i_item_id,
        hvi.i_product_name,
        hvi.order_count,
        hvi.total_quantity_sold,
        hvi.avg_sales_price,
        hvi.total_sales,
        ROW_NUMBER() OVER (ORDER BY hvi.total_sales DESC) AS sales_rank
    FROM 
        HighValueItems hvi
)
SELECT 
    f.i_item_id,
    f.i_product_name,
    f.order_count,
    f.total_quantity_sold,
    f.avg_sales_price,
    f.total_sales,
    f.sales_rank
FROM 
    FinalResults f
WHERE 
    f.sales_rank <= 10
ORDER BY 
    f.total_sales DESC;
