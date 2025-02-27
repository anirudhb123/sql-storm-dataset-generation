
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0 
    AND i.i_rec_start_date <= CURRENT_DATE 
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CURRENT_DATE)
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        rs.web_site_sk,
        cd.c_customer_sk,
        SUM(rs.ws_net_paid) AS total_net_paid,
        COUNT(*) AS total_transactions
    FROM RankedSales rs
    JOIN CustomerDetails cd ON rs.web_site_sk = cd.c_customer_sk
    GROUP BY rs.web_site_sk, cd.c_customer_sk
),
FinalSalesInfo AS (
    SELECT 
        si.web_site_sk,
        si.c_customer_sk,
        si.total_net_paid,
        si.total_transactions,
        CASE 
            WHEN si.total_net_paid IS NULL THEN 'No Sales'
            WHEN si.total_transactions = 0 THEN 'No Transactions'
            ELSE 'Normal'
        END AS sales_status
    FROM SalesInfo si
    WHERE si.total_net_paid > (SELECT AVG(total_net_paid) FROM SalesInfo)
)
SELECT 
    w.w_warehouse_id,
    COALESCE(fs.total_net_paid, 0) AS total_net_paid,
    fs.sales_status,
    COUNT(CASE WHEN fs.sales_status = 'Normal' THEN 1 END) OVER(PARTITION BY fs.sales_status) AS status_count
FROM warehouse w
LEFT JOIN FinalSalesInfo fs ON w.w_warehouse_sk = fs.web_site_sk
WHERE fs.total_net_paid IS NOT NULL
AND EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 50)
    AND ss.ss_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
)
ORDER BY w.w_warehouse_id DESC, total_net_paid DESC;
