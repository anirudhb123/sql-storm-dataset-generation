
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.store_sk,
        ss.customer_sk,
        ss.quantity,
        ss.net_profit,
        1 AS depth
    FROM 
        store_sales ss 
    WHERE 
        ss.sold_date_sk = (SELECT MAX(ss_inner.sold_date_sk) FROM store_sales ss_inner)
    
    UNION ALL
    
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.store_sk,
        ss.customer_sk,
        ss.quantity,
        ss.net_profit,
        depth + 1
    FROM 
        store_sales ss 
    JOIN 
        SalesCTE cte ON ss.store_sk = cte.store_sk AND ss.customer_sk = cte.customer_sk
    WHERE 
        cte.depth < 5
), 
AggregateSales AS (
    SELECT 
        s.item_sk,
        COUNT(s.customer_sk) AS customer_count,
        SUM(s.net_profit) AS total_profit,
        AVG(s.quantity) AS average_quantity
    FROM 
        SalesCTE s 
    GROUP BY 
        s.item_sk
),
CustomerDetails AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    a.item_sk,
    a.customer_count,
    a.total_profit,
    a.average_quantity,
    cd.first_name,
    cd.last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating
FROM 
    AggregateSales a
JOIN 
    CustomerDetails cd ON a.customer_count = (SELECT MAX(customer_count) FROM AggregateSales)
WHERE 
    cd.rn <= 10
ORDER BY 
    a.total_profit DESC, 
    cd.first_name ASC;
