
WITH RankedSales AS (
    SELECT 
        ws.ws_store_sk,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws_store_sk ORDER BY ws_net_paid_inc_tax DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid_inc_tax IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 0 
            ELSE cd.cd_dep_count 
        END AS dependent_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        r.ws_store_sk,
        SUM(r.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT r.ws_item_sk) AS unique_items_sold
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
    GROUP BY 
        r.ws_store_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        CASE 
            WHEN i.i_current_price > (
                SELECT AVG(i2.i_current_price) 
                FROM item i2 WHERE i2.i_item_sk != i.i_item_sk
            ) 
            THEN 'Above Average' 
            ELSE 'Below Average' 
        END AS price_comparison
    FROM 
        item i
)

SELECT 
    s.s_store_id,
    SUM(ss.total_sales) AS total_net_sales,
    cd.credit_rating,
    cd.dependent_count,
    COUNT(DISTINCT id.i_item_sk) AS total_items_in_store,
    SUM(CASE WHEN id.price_comparison = 'Above Average' THEN 1 ELSE 0 END) AS above_average_price_count
FROM 
    SalesSummary ss
JOIN 
    store s ON s.s_store_sk = ss.ws_store_sk
JOIN 
    CustomerDetails cd ON cd.c_customer_sk IN (SELECT DISTINCT ws.ws_ship_customer_sk FROM web_sales ws WHERE ws.ws_ship_date_sk = ss.ws_sold_date_sk)
LEFT JOIN 
    ItemDetails id ON id.i_item_sk IN (
        SELECT ws.ws_item_sk 
        FROM web_sales ws 
        WHERE ws.ws_sold_date_sk = ss.ws_sold_date_sk 
        AND ws.ws_store_sk = ss.ws_store_sk
    )
GROUP BY 
    s.s_store_id, cd.credit_rating, cd.dependent_count
HAVING 
    total_net_sales > ALL (SELECT AVG(total_sales) FROM SalesSummary)
ORDER BY 
    total_net_sales DESC;
