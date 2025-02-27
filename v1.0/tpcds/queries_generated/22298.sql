
WITH ranked_sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_bill_customer_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_date < CURRENT_DATE - INTERVAL '1 day'
        )
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT r.r_reason_sk) AS reason_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        OR (cd.cd_gender = 'F' AND cd.cd_dep_count > 1)
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
income_distribution AS (
    SELECT 
        CASE 
            WHEN hd.hd_income_band_sk < 5 THEN 'Low Income'
            WHEN hd.hd_income_band_sk BETWEEN 5 AND 10 THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_band,
        COUNT(*) AS customer_count
    FROM 
        household_demographics hd
    GROUP BY 
        1
),
final_report AS (
    SELECT 
        cs.c_customer_id,
        MAX(s.total_sales) AS max_sales,
        MIN(s.total_sales) AS min_sales,
        i.income_band,
        SUM(COALESCE(r.reason_count, 0)) AS sum_reason_count
    FROM 
        customer_summary cs
    JOIN (
        SELECT 
            ws_bill_customer_sk,
            SUM(ws_sales_price) AS total_sales
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk
    ) s ON cs.c_customer_id = s.ws_bill_customer_sk
    JOIN income_distribution i ON cs.reason_count > 0
    LEFT JOIN (
        SELECT DISTINCT 
            wr_returning_customer_sk, 
            COUNT(*) AS reason_count 
        FROM 
            web_returns 
        GROUP BY 
            wr_returning_customer_sk
    ) r ON r.wr_returning_customer_sk = cs.c_customer_id
    GROUP BY 
        cs.c_customer_id, i.income_band
)
SELECT 
    fr.c_customer_id,
    fr.max_sales,
    fr.min_sales,
    fr.income_band,
    fr.sum_reason_count
FROM 
    final_report fr
WHERE 
    fr.max_sales > (
        SELECT AVG(total_sales) 
        FROM (
            SELECT 
                ws_bill_customer_sk, 
                SUM(ws_sales_price) AS total_sales 
            FROM 
                web_sales 
            GROUP BY 
                ws_bill_customer_sk
        ) avg_sales
    )
ORDER BY 
    fr.sum_reason_count DESC, 
    fr.c_customer_id
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
