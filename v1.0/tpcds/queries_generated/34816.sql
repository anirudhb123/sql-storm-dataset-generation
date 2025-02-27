
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank_sales
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk
),
Ranked_Stores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(total_sales) AS store_total_sales,
        SUM(total_profit) AS store_total_profit
    FROM 
        Sales_CTE
    JOIN 
        store ON Sales_CTE.ss_store_sk = store.s_store_sk
    GROUP BY 
        s_store_sk, s_store_name
),
Customer_Preferences AS (
    SELECT 
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        ce.ca_state,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ce ON c.c_current_addr_sk = ce.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_preferred_cust_flag, ce.ca_state, cd.cd_gender
)
SELECT 
    s_store_name,
    SUM(s.store_total_sales) AS total_sales,
    AVG(s.store_total_profit) AS avg_profit,
    c.ca_state,
    c.cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    COALESCE(NULLIF(SUM(s.total_sales) / NULLIF(COUNT(DISTINCT c.c_customer_sk), 0), 0), 0) AS sales_per_customer
FROM 
    Ranked_Stores s
FULL OUTER JOIN 
    Customer_Preferences c ON s.s_store_sk = c.c_customer_sk
WHERE 
    c.c_preferred_cust_flag = 'Y'
GROUP BY 
    s_store_name, c.ca_state, c.cd_gender
HAVING 
    sales_per_customer > 100
ORDER BY 
    total_sales DESC, avg_profit DESC;
