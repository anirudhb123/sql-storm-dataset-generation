
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.web_site_id, ws_sold_date_sk, ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END), 0) AS married_count,
        COALESCE(SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END), 0) AS male_count,
        ROUND(AVG(cd_purchase_estimate), 2) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        ROUND(AVG(cd_purchase_estimate), 2) > 1000
),
SeasonalReturns AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS unique_return_tickets
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023) 
            AND d_weekend = 'Y'
        )
    GROUP BY 
        sr_returned_date_sk
)
SELECT 
    ws.web_site_id,
    r.total_sales,
    h.c_customer_id,
    h.married_count,
    h.male_count,
    h.avg_purchase_estimate,
    sr.total_returns,
    sr.unique_return_tickets
FROM 
    RankedSales r
JOIN 
    HighValueCustomers h ON h.avg_purchase_estimate > r.total_sales / NULLIF(sqrt(h.married_count + 1), 0)
LEFT JOIN 
    SeasonalReturns sr ON r.ws_sold_date_sk = sr.sr_returned_date_sk
WHERE 
    r.sales_rank = 1
    AND (sr.total_returns IS NULL OR sr.total_returns > 0)
ORDER BY 
    r.total_sales DESC, 
    h.avg_purchase_estimate ASC;
