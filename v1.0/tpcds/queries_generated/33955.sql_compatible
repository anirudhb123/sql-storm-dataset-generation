
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk

    UNION ALL

    SELECT 
        ws_sold_date_sk,
        total_quantity * 1.1 AS total_quantity,
        total_profit * 1.1 AS total_profit,
        rn
    FROM 
        SalesCTE
    WHERE 
        rn <= 10
),

CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_tickets,
        COALESCE(SUM(s.ss_net_profit), 0) AS total_spent,
        CASE 
            WHEN SUM(s.ss_net_profit) < 100 THEN 'Low' 
            WHEN SUM(s.ss_net_profit) BETWEEN 100 AND 500 THEN 'Medium' 
            ELSE 'High' 
        END AS spending_category
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
)

SELECT 
    ca.ca_city,
    cd.cd_gender,
    cs.spending_category,
    SUM(cs.total_spent) AS total_spending,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    MAX(sale.total_quantity) AS max_quantity,
    MIN(sale.total_profit) AS min_profit,
    AVG(sale.total_profit) AS avg_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    CustomerSummary cs ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    SalesCTE sale ON sale.ws_sold_date_sk = c.c_first_sales_date_sk
WHERE 
    ca.ca_country IS NOT NULL
    AND ca.ca_city NOT IN ('Sample City 1', 'Sample City 2')
GROUP BY 
    ca.ca_city, cd.cd_gender, cs.spending_category
HAVING 
    SUM(cs.total_spent) > 5000
ORDER BY 
    total_spending DESC NULLS LAST;
