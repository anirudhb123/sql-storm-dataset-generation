
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        s.s_store_name,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2024)
),
FilteredSales AS (
    SELECT 
        item.i_item_id,
        SUM(CASE WHEN rank = 1 THEN ws_sales_price ELSE 0 END) AS top_sales,
        AVG(ws_sales_price) AS avg_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        RankedSales r
    JOIN 
        item ON r.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id
),
FinalResults AS (
    SELECT 
        f.i_item_id,
        f.top_sales,
        f.avg_sales,
        f.total_orders,
        CASE
            WHEN f.top_sales > 0 THEN 'Top Item'
            ELSE 'No Sales'
        END AS sales_category
    FROM 
        FilteredSales f
    WHERE 
        f.avg_sales IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        f.*
    FROM 
        customer_demographics cd 
    CROSS JOIN 
        FinalResults f
)

SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    AVG(cd.avg_sales) AS avg_sales_by_gender,
    SUM(CASE WHEN f.top_sales > 100 THEN 1 ELSE 0 END) AS high_sales_count
FROM 
    CustomerDemographics cd
JOIN 
    FinalResults f ON 1=1
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
HAVING 
    AVG(cd.avg_sales) IS NOT NULL
ORDER BY 
    cd.cd_gender, cd.cd_marital_status;
