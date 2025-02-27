
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_sales,
        1 AS hierarchy_level
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk BETWEEN 1 AND 365
    GROUP BY s_store_sk

    UNION ALL

    SELECT 
        s.s_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_sales,
        sh.hierarchy_level + 1
    FROM 
        store s
        JOIN SalesHierarchy sh ON s.s_store_sk = sh.s_store_sk
        JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss_sold_date_sk BETWEEN 1 AND 365
    GROUP BY s.s_store_sk, sh.hierarchy_level
),
CustomerNetProfit AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_net_profit) AS customer_net_profit
    FROM 
        web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY c.c_customer_sk
),
AggregateData AS (
    SELECT 
        d.d_year,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(COALESCE(cnp.customer_net_profit, 0)) AS total_customer_net_profit,
        SUM(sh.total_net_profit) AS total_store_net_profit
    FROM 
        date_dim d
        LEFT JOIN customer c ON (EXTRACT(YEAR FROM d.d_date) = c.c_birth_year OR c.c_birth_year IS NULL)
        LEFT JOIN customer_net_profit cnp ON c.c_customer_sk = cnp.c_customer_sk
        LEFT JOIN SalesHierarchy sh ON c.c_current_addr_sk = sh.s_store_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY d.d_year
)
SELECT 
    ad.d_year,
    ad.unique_customers,
    ad.avg_purchase_estimate,
    ad.total_customer_net_profit,
    ad.total_store_net_profit,
    CASE 
        WHEN ad.total_store_net_profit IS NOT NULL 
        THEN ad.total_customer_net_profit / ad.total_store_net_profit
        ELSE 0 
    END AS profit_ratio,
    ROW_NUMBER() OVER (ORDER BY ad.total_customer_net_profit DESC) AS customer_rank
FROM 
    AggregateData ad
ORDER BY 
    ad.total_customer_net_profit DESC
LIMIT 10;
