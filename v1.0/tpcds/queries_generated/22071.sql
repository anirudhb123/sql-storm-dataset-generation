
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
IncomeGroup AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS income_group
    FROM 
        customer_demographics cd
),
FilteredSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_profit,
        cs.total_store_profit,
        ig.income_group
    FROM 
        CustomerSales cs
    JOIN 
        IncomeGroup ig ON cs.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = cs.c_customer_sk)
    WHERE 
        cs.total_web_profit IS NOT NULL AND cs.total_store_profit IS NOT NULL
),
RankedSales AS (
    SELECT 
        fs.c_customer_id,
        fs.total_web_profit,
        fs.total_store_profit,
        fs.income_group,
        RANK() OVER (PARTITION BY fs.income_group ORDER BY (fs.total_web_profit + fs.total_store_profit) DESC) AS sales_rank
    FROM 
        FilteredSales fs
)
SELECT 
    rs.c_customer_id,
    rs.total_web_profit,
    rs.total_store_profit,
    rs.income_group,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Not Top 10'
    END AS ranking_category,
    COALESCE(CONCAT('Customer ID: ', rs.c_customer_id, ' | Income Group: ', rs.income_group), 'Data Missing') AS customer_info
FROM 
    RankedSales rs
WHERE 
    rs.total_web_profit < (SELECT AVG(total_web_profit) FROM FilteredSales) 
    OR rs.total_store_profit < (SELECT AVG(total_store_profit) FROM FilteredSales)
ORDER BY 
    rs.income_group, rs.sales_rank;
