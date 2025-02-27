
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_order_number END) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    cust.c_first_name,
    cust.c_last_name,
    cust.cd_gender,
    cust.cd_marital_status,
    COALESCE(SUM(sales.total_profit), 0) AS overall_profit,
    CASE 
        WHEN COUNT(sales.cs_item_sk) = 0 
        THEN 'No purchases' 
        ELSE 'Purchased items' 
    END AS purchase_status,
    current_date AS report_date
FROM 
    CustomerDetails cust
LEFT JOIN 
    RankedSales sales ON sales.cs_item_sk IN (
        SELECT 
            DISTINCT cs_item_sk 
        FROM 
            catalog_sales 
        WHERE 
            cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
    )
WHERE 
    cust.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
GROUP BY 
    cust.c_first_name, cust.c_last_name, cust.cd_gender, cust.cd_marital_status
HAVING 
    overall_profit IS NOT NULL
ORDER BY 
    overall_profit DESC
LIMIT 10;
