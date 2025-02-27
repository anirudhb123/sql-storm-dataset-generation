
WITH RankedRefunds AS (
    SELECT 
        COALESCE(ws.ws_sold_date_sk, ss.ss_sold_date_sk) AS sold_date,
        CASE 
            WHEN ws.ws_net_profit < 0 THEN 'Web'
            WHEN ss.ss_net_profit < 0 THEN 'Store'
            ELSE 'None'
        END AS source,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_refund,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(ws.ws_sold_date_sk, ss.ss_sold_date_sk) ORDER BY SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) DESC) AS rn
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    GROUP BY 
        COALESCE(ws.ws_sold_date_sk, ss.ss_sold_date_sk)
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_date_id,
        MAX(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
        COUNT(DISTINCT CASE WHEN cd.cd_marital_status = 'M' THEN c.c_customer_id END) AS married_count,
        MAX(d.d_year) AS last_year_active
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date_id
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    r.total_refund,
    SUM(CASE WHEN r.source = 'Web' THEN r.total_refund ELSE 0 END) AS web_refund_total,
    SUM(CASE WHEN r.source = 'Store' THEN r.total_refund ELSE 0 END) AS store_refund_total
FROM 
    CustomerStats cs
LEFT JOIN 
    RankedRefunds r ON cs.last_year_active = r.sold_date
WHERE 
    (web_refund_total + store_refund_total) > 0
GROUP BY 
    cs.c_customer_id, cs.c_first_name, cs.c_last_name
HAVING 
    SUM(CASE WHEN r.source IS NULL THEN 1 ELSE 0 END) = 0
ORDER BY 
    web_refund_total DESC, store_refund_total DESC;
