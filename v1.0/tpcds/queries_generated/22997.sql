
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighPerformingSales AS (
    SELECT
        rs.ws_item_sk,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales,
        COALESCE(NULLIF(i.i_current_price, 0), 1) AS effective_price,
        (rs.total_sales / NULLIF(SUM(rs.total_sales) OVER (), 0)) * 100 AS sales_percentage
    FROM 
        RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 5
),
CustomerSegment AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesBreakdown AS (
    SELECT 
        hps.ws_item_sk,
        hps.i_item_desc,
        hps.total_quantity,
        hps.total_sales,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.customer_count,
        (hps.total_sales / NULLIF(cs.customer_count, 0)) AS average_sales_per_customer
    FROM 
        HighPerformingSales hps
    LEFT JOIN CustomerSegment cs ON hps.ws_item_sk = (SELECT TOP 1 ws_item_sk FROM web_sales WHERE ws_item_sk = hps.ws_item_sk ORDER BY ws_sold_date_sk DESC)
)
SELECT 
    sb.ws_item_sk,
    sb.i_item_desc,
    sb.total_quantity,
    sb.total_sales,
    sb.average_sales_per_customer,
    CASE 
        WHEN sb.average_sales_per_customer > 100 THEN 'High'
        WHEN sb.average_sales_per_customer BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category,
    CASE 
        WHEN sb.customer_count IS NULL THEN 'Undefined'
        ELSE 'Defined'
    END AS customer_status
FROM 
    SalesBreakdown sb
WHERE 
    sb.total_sales > 1000
ORDER BY 
    sb.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
