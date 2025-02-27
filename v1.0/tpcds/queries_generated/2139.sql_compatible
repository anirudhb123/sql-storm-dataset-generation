
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
    JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    WHERE 
        ss.sales_rank <= 10
),
customer_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_dep_count) AS max_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    id.i_item_desc,
    id.i_brand,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.max_dep_count,
    CASE 
        WHEN cs.avg_purchase_estimate IS NULL THEN 'No Data'
        ELSE 'Data Available'
    END AS data_availability,
    RANK() OVER (ORDER BY cs.customer_count DESC) AS customer_rank
FROM 
    item_details id
LEFT JOIN 
    customer_summary cs ON id.i_item_sk IN (
        SELECT 
            DISTINCT ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
    )
ORDER BY 
    customer_rank, id.i_item_desc;
