
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(s.total_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(s.total_sales), 0) AS total_sales_amount
    FROM 
        item i
    LEFT JOIN SalesCTE s ON i.i_item_sk = s.ws_item_sk OR i.i_item_sk = s.cs_item_sk
    GROUP BY 
        i.i_item_id
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender
),
TopItems AS (
    SELECT 
        i.i_item_id,
        s.total_quantity_sold,
        s.total_sales_amount,
        RANK() OVER (ORDER BY s.total_sales_amount DESC) AS sales_rank
    FROM 
        SalesSummary s
    JOIN 
        item i ON s.i_item_id = i.i_item_id
)
SELECT 
    t.i_item_id,
    t.total_quantity_sold,
    t.total_sales_amount,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate
FROM 
    TopItems t
LEFT JOIN 
    CustomerStats c ON t.total_sales_amount > 1000
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales_amount DESC;
