
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_profit DESC) AS rank,
        COUNT(*) OVER (PARTITION BY ws.web_site_id) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
    AND 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 3) 
                                AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 5)
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(CASE WHEN c.c_current_addr_sk IS NOT NULL THEN 1 ELSE 0 END), 0) AS valid_address_count,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS marital_ratio
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
FinalResults AS (
    SELECT 
        cs.c_customer_id,
        cs.order_count,
        cs.valid_address_count,
        cs.marital_ratio,
        rs.web_site_id,
        rs.ws_order_number,
        rs.ws_net_profit
    FROM 
        CustomerStats cs
    LEFT JOIN 
        RankedSales rs ON cs.order_count > 0 AND cs.valid_address_count IS NOT NULL
    WHERE 
        cs.marital_ratio IS NOT NULL
)
SELECT 
    fr.c_customer_id,
    fr.web_site_id,
    fr.ws_order_number,
    fr.ws_net_profit,
    CASE
        WHEN fr.ws_net_profit > 100 THEN 'High Profit'
        WHEN fr.ws_net_profit BETWEEN 50 AND 100 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    NULLIF(fr.valid_address_count, 0) AS adjusted_address_count,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = fr.c_customer_id) AS store_sales_count
FROM 
    FinalResults fr
WHERE 
    fr.ws_net_profit IS NOT NULL AND fr.ws_order_number IS NOT NULL
ORDER BY 
    profit_category DESC, fr.ws_net_profit DESC;
