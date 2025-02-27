
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        MIN(ws_sold_date_sk) AS first_sale_date,
        MAX(ws_sold_date_sk) AS last_sale_date
    FROM web_sales
    GROUP BY ws_item_sk
), 
RankedSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        s.first_sale_date,
        s.last_sale_date,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM SalesCTE s
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender, 
        cd_marital_status,
        cd.education_status AS education_level,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status, cd.education_status
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    rs.total_quantity,
    rs.total_sales,
    cdc.gender,
    cdc.education_level,
    cdc.customer_count,
    cdc.avg_purchase_estimate,
    (CASE 
        WHEN cdc.cd_marital_status = 'M' THEN 'Married'
        WHEN cdc.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
     END) AS marital_status,
    (SELECT TOP 1 d.d_day_name 
     FROM date_dim d 
     WHERE d.d_date_sk BETWEEN rs.first_sale_date AND rs.last_sale_date 
     ORDER BY d.d_date DESC) AS last_sale_day
FROM RankedSales rs
JOIN item i ON rs.ws_item_sk = i.i_item_sk
LEFT JOIN CustomerDemographics cdc ON cdc.customer_count > 0
WHERE (rs.total_quantity IS NOT NULL AND rs.total_sales > 10000)
  AND (EXISTS (SELECT 1 
                FROM store_sales ss 
                WHERE ss.ss_item_sk = rs.ws_item_sk 
                  AND ss.ss_net_paid_inc_tax > 200))
ORDER BY rs.sales_rank
FETCH FIRST 10 ROWS ONLY;
