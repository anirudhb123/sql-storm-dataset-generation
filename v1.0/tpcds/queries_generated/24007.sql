
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY ws.web_site_sk
),
CustomerGender AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN c.c_birth_month IS NULL THEN 1 ELSE 0 END) AS unknown_birth_month,
        MAX(cd.cd_purchase_estimate) AS max_estimate
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_gender
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
OutboundReturns AS (
    SELECT 
        wr_refunded_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_order_number) AS total_returns
    FROM web_returns
    WHERE wr_return_quantity > 0
    GROUP BY wr_refunded_customer_sk
),
Winners AS (
    SELECT 
        s.store_sk,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_sales,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit
    FROM store s
    LEFT JOIN store_returns sr ON s.s_store_sk = sr.s_store_sk
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY s.store_sk
)
SELECT 
    S.web_site_sk,
    S.total_sales,
    CG.cd_gender,
    CG.customer_count,
    HVC.full_name,
    HVC.cd_purchase_estimate,
    COALESCE(ORB.total_return_amt, 0) AS total_return_amt,
    COALESCE(ORB.total_returns,0) AS total_returns,
    W.total_net_profit
FROM SalesCTE S
JOIN CustomerGender CG ON S.web_site_sk = (SELECT MIN(web_site_sk) FROM web_site)
LEFT JOIN HighValueCustomers HVC ON HVC.rank <= 5
LEFT JOIN OutboundReturns ORB ON HVC.c_customer_id = ORB.wr_refunded_customer_sk
LEFT JOIN Winners W ON S.web_site_sk = W.store_sk
WHERE (CG.unknown_birth_month > 0 OR CG.customer_count > 100)
AND S.rank_sales < 10
ORDER BY S.total_sales DESC, W.total_net_profit ASC;
