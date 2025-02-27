
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sold_date_sk, 
        ws.ws_quantity, 
        ws.ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
), 
TopSales AS (
    SELECT 
       rs.ws_item_sk, 
        SUM(rs.ws_net_profit) AS total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rnk <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerSegment AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        CASE 
            WHEN cd.cd_birth_month BETWEEN 6 AND 8 THEN 'Summer'
            WHEN cd.cd_birth_month BETWEEN 9 AND 11 THEN 'Fall'
            ELSE 'Other'
        END AS season
    FROM 
        customer_demographics cd
)
SELECT 
    cs.c_customer_sk,
    SUM(ts.total_profit) AS total_profit,
    COUNT(DISTINCT cs.c_customer_id) AS customer_count,
    AVG(cd.cd_dep_employed_count) AS avg_employed_deps,
    MAX(ws.ws_net_paid) AS max_net_paid
FROM 
    customer cs
LEFT JOIN 
    TopSales ts ON cs.c_current_cdemo_sk = ts.ws_item_sk 
LEFT JOIN 
    CustomerSegment cd ON cs.c_current_hdemo_sk = cd.cd_demo_sk
WHERE 
    cs.c_first_shipto_date_sk IS NOT NULL 
    AND cs.c_last_review_date_sk IS NOT NULL 
GROUP BY 
    cs.c_customer_sk
HAVING 
    SUM(ts.total_profit) > 0
ORDER BY 
    total_profit DESC
LIMIT 10;
