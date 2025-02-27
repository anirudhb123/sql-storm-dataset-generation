
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.net_profit DESC) AS rn,
        DENSE_RANK() OVER (ORDER BY ws.net_profit) AS dr
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
      AND (c.c_preferred_cust_flag = 'Y' OR 
           c.c_birth_month = MONTH(NOW()) AND c.c_birth_day = DAY(NOW())) 
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE 
                WHEN cd.cd_credit_rating IS NULL THEN 0 
                ELSE 1 
            END) AS non_null_ratings
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender
), WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(cv.inv_quantity_on_hand) AS total_inventory,
        SUM(ws.net_profit) AS total_net_profit
    FROM warehouse w
    LEFT JOIN inventory cv ON w.w_warehouse_sk = cv.inv_warehouse_sk
    LEFT JOIN web_sales ws ON cv.inv_item_sk = ws.ws_item_sk
    WHERE w.w_gmt_offset < 0
    GROUP BY w.w_warehouse_id
), BlendedSales AS (
    SELECT 
        r.web_site_id,
        r.net_profit AS web_profit,
        ws.total_net_profit AS warehouse_profit,
        COALESCE(ws.total_net_profit, 0) + COALESCE(r.net_profit, 0) AS blended_profit
    FROM RankedSales r
    FULL OUTER JOIN WarehouseSales ws ON r.web_site_id = ws.w_warehouse_id
)
SELECT 
    b.web_site_id,
    b.blended_profit,
    cd.cd_gender,
    cd.customer_count,
    cd.avg_purchase_estimate,
    CASE 
        WHEN cd.non_null_ratings > 0 THEN 'Has Ratings' 
        ELSE 'No Ratings' 
    END AS rating_status
FROM BlendedSales b
JOIN CustomerDemographics cd ON (cd.customer_count > 0 AND (b.blended_profit != 0 OR b.blended_profit IS NULL))
WHERE b.blended_profit IS NOT NULL
ORDER BY b.blended_profit DESC, cd.avg_purchase_estimate ASC
LIMIT 10;
