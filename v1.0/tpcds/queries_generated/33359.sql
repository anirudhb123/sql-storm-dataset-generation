
WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(COALESCE(ss.ss_net_profit, 0)) > 5000
    UNION ALL
    SELECT 
        p.c_customer_sk,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_sales
    FROM 
        customer p
    JOIN 
        web_sales ws ON p.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        p.c_customer_sk
    HAVING 
        SUM(COALESCE(ws.ws_net_profit, 0)) > 3000
),
RankedSales AS (
    SELECT 
        c.c_customer_sk,
        s.total_sales,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SalesCTE s
    JOIN 
        customer c ON s.c_customer_sk = c.c_customer_sk
)
SELECT 
    ca.ca_state,
    COUNT(DISTINCT r.c_customer_sk) AS num_customers,
    AVG(r.total_sales) AS average_sales,
    MAX(r.total_sales) AS max_sales
FROM 
    RankedSales r
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = r.c_customer_sk)
WHERE 
    EXISTS (
        SELECT 1
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = r.c_customer_sk
        AND cd.cd_income_band_sk BETWEEN 1 AND 5
        AND cd.cd_gender = 'M'
    )
GROUP BY 
    ca.ca_state
ORDER BY 
    num_customers DESC;
