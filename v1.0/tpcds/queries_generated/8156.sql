
WITH LastYearSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = (SELECT MAX(d_year) FROM date_dim) - 1)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_product_name,
        ls.total_sales,
        ls.total_orders
    FROM 
        LastYearSales ls
    JOIN 
        item i ON ls.ws_item_sk = i.i_item_sk
    ORDER BY 
        ls.total_sales DESC
    LIMIT 10
),
CustomerSegment AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        hd_income_band_sk
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd_demo_sk = hd.hd_demo_sk
    WHERE 
        hd_income_band_sk IS NOT NULL
),
SalesDistribution AS (
    SELECT 
        ts.i_item_id,
        cs.cd_gender,
        COUNT(*) AS order_count,
        AVG(ls.total_sales) AS avg_sales
    FROM 
        TopItems ts
    JOIN 
        web_sales ws ON ts.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerSegment cs ON ws.ws_bill_cdemo_sk = cs.cd_demo_sk
    GROUP BY 
        ts.i_item_id, cs.cd_gender
)
SELECT 
    sd.i_item_id,
    sd.cd_gender,
    sd.order_count,
    sd.avg_sales,
    RANK() OVER (PARTITION BY sd.i_item_id ORDER BY sd.order_count DESC) AS rank_within_item
FROM 
    SalesDistribution sd
ORDER BY 
    sd.i_item_id, rank_within_item;
