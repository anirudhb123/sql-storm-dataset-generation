
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        total_quantity,
        total_sales + (SELECT COALESCE(SUM(cs_net_paid), 0) FROM catalog_sales WHERE cs_item_sk = ws_item_sk AND cs_sold_date_sk = SalesData.ws_sold_date_sk) AS new_sales
    FROM 
        SalesData
    WHERE 
        rank < 5
),
AggregatedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(total_quantity) AS total_quantity, 
        SUM(total_sales) AS total_sales
    FROM 
        SalesData
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COALESCE(AS.total_quantity, 0) AS total_quantity,
        COALESCE(AS.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(AS.total_sales, 0) = 0 THEN NULL
            ELSE (COALESCE(AS.total_sales, 0) / (SELECT SUM(total_sales) FROM AggregatedSales)) * 100
        END AS sales_percentage
    FROM 
        item
    LEFT JOIN 
        AggregatedSales AS ON item.i_item_sk = AS.ws_item_sk
),
SalesComparison AS (
    SELECT 
        item.i_item_id, 
        item.i_product_name, 
        T.total_quantity,
        T.total_sales,
        T.sales_percentage,
        COALESCE(NULLIF(T.sales_percentage, L.sales_percentage), 0) AS change_from_last_year
    FROM TopSales T
    LEFT JOIN 
        (SELECT 
             ws_item_sk, 
             SUM(total_sales) AS sales_percentage 
         FROM 
             AggregatedSales 
         WHERE 
             YEAR = YEAR(CURRENT_DATE) - 1
         GROUP BY ws_item_sk) L 
    ON T.ws_item_sk = L.ws_item_sk
)
SELECT 
    CC.cc_name,
    CC.cc_city,
    SUM(SS.ss_ext_sales_price) AS total_store_sales,
    SUM(WR.wr_net_loss) AS total_web_returns,
    COUNT(DISTINCT C.c_customer_sk) AS unique_customers,
    COUNT(DISTINCT SC.s_store_sk) AS unique_stores,
    SUM(IF(item.i_formulation = 'Packaged', 1, 0)) AS packaged_products,
    SUM(CASE WHEN T.sales_percentage IS NOT NULL AND T.sales_percentage > 0 THEN T.sales_percentage ELSE 0 END) AS positive_sales_percentage
FROM 
    customer C
JOIN 
    store_sales SS ON C.c_customer_sk = SS.ss_customer_sk 
JOIN 
    web_returns WR ON C.c_customer_sk = WR.w_returning_customer_sk
JOIN 
    SalesComparison T ON SS.ss_item_sk = T.ws_item_sk
JOIN 
    call_center CC ON C.c_customer_sk = CC.cc_call_center_sk
JOIN 
    store SC ON SS.ss_store_sk = SC.s_store_sk
GROUP BY 
    CC.cc_name,
    CC.cc_city
ORDER BY 
    total_store_sales DESC;
