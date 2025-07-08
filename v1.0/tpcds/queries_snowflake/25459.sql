
WITH GenderDetails AS (
    SELECT 
        cd_gender, 
        COUNT(c_customer_sk) AS customer_count, 
        LISTAGG(CONCAT(c_first_name, ' ', c_last_name), '; ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS full_names
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
RevenueDetails AS (
    SELECT 
        'Web' AS sales_channel,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        LISTAGG(CONCAT(i_item_desc, ' (', ws_quantity, ' sold)'), '; ') WITHIN GROUP (ORDER BY i_item_desc) AS item_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        sales_channel
    UNION ALL
    SELECT 
        'Store' AS sales_channel,
        SUM(ss_net_paid_inc_tax) AS total_revenue,
        LISTAGG(CONCAT(i_item_desc, ' (', ss_quantity, ' sold)'), '; ') WITHIN GROUP (ORDER BY i_item_desc) AS item_sales
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY 
        sales_channel
)
SELECT 
    gd.cd_gender,
    gd.customer_count,
    gd.full_names,
    rd.sales_channel,
    rd.total_revenue,
    rd.item_sales
FROM 
    GenderDetails gd
CROSS JOIN 
    RevenueDetails rd
ORDER BY 
    gd.cd_gender, 
    rd.sales_channel;
