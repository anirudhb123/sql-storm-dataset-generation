
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 1) 
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 12)
    GROUP BY 
        ws_item_sk
), Top_Items AS (
    SELECT 
        s.ws_item_sk, 
        i.i_item_desc, 
        s.total_sales
    FROM 
        Sales_CTE s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.sales_rank <= 10
), Customer_Spend AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_spend
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk
), Customer_Info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status 
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    SUM(cs.total_spend) AS total_customer_spend, 
    ti.i_item_desc
FROM 
    Customer_Info ci
LEFT JOIN 
    Customer_Spend cs ON ci.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    Top_Items ti ON cs.total_spend = (
        SELECT 
            MAX(total_spend) 
        FROM 
            Customer_Spend 
        WHERE 
            c_customer_sk = ci.c_customer_sk
    )
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ti.i_item_desc
HAVING 
    SUM(cs.total_spend) > 1000
ORDER BY 
    total_customer_spend DESC;
