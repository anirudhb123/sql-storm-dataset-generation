
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT s.ss_ticket_number) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales s ON s.ss_customer_sk = c.c_customer_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN 
        date_dim d ON d.d_date_sk = s.ss_sold_date_sk OR d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        c.c_customer_sk, d.d_year, cd.cd_gender, cd.cd_marital_status
),
income_bracket AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN CONCAT('Band ', hd.hd_income_band_sk)
            ELSE 'No Income Data' 
        END AS income_category,
        COUNT(*) AS income_count
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, hd.hd_income_band_sk
),
final_report AS (
    SELECT 
        ci.c_customer_sk,
        ci.d_year,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.total_store_sales,
        ci.total_web_sales,
        ib.income_category,
        fs.total_quantity,
        fs.total_net_paid
    FROM 
        customer_info ci
    JOIN 
        income_bracket ib ON ci.c_customer_sk = ib.c_customer_sk
    LEFT JOIN 
        sales_summary fs ON fs.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk)
    WHERE 
        (ci.total_store_sales + ci.total_web_sales > 0 AND ci.cd_gender IS NOT NULL)
      OR
        ci.total_web_sales > (
            SELECT AVG(total_web_sales)
            FROM customer_info
        )
    ORDER BY 
        ci.total_net_paid DESC NULLS LAST
)
SELECT 
    COUNT(*) AS num_report_entries,
    AVG(total_net_paid) AS avg_total_net_paid,
    MAX(total_quantity) AS max_total_quantity,
    MIN(total_web_sales) AS min_total_web_sales
FROM 
    final_report
WHERE 
    total_web_sales IS NOT NULL
   AND
    (total_store_sales > 0 OR total_web_sales > 0);
