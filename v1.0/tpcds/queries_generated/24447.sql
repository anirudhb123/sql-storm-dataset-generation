
WITH RECURSIVE SalesAnalytics AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales ws
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL AND 
        i.i_rec_start_date <= CURRENT_DATE AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    sa.ws_item_sk,
    i.i_item_desc,
    sa.total_sales,
    sa.total_revenue,
    CASE 
        WHEN sa.rank = 1 THEN 'Top Seller'
        ELSE 'Regular Item'
    END AS sales_ranking
FROM 
    SalesAnalytics sa
INNER JOIN 
    item i ON sa.ws_item_sk = i.i_item_sk
WHERE 
    sa.total_sales > (
        SELECT 
            AVG(total_sales) 
        FROM 
            (SELECT 
                SUM(ws_quantity) AS total_sales 
             FROM 
                web_sales 
             GROUP BY 
                ws_item_sk
            ) AS average_sales
    )
OR 
    (SELECT 
        COUNT(*) 
     FROM 
        customer_demographics cd 
     WHERE 
        cd.cd_credit_rating = 'Excellent' 
        AND cd.cd_dep_count IS NOT NULL
    ) > 5000
ORDER BY 
    sa.total_revenue DESC;

-- Adding a chaotic ORDER BY clause that mixes different columns
ORDER BY
    CASE WHEN (i.i_color IS NULL) THEN 1 ELSE 0 END,
    sa.total_sales DESC,
    RANDOM();
