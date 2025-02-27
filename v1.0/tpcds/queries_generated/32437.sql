
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        0 AS level
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    
    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ch.level + 1
    FROM 
        customerHierarchy ch
    JOIN 
        customer c ON c.c_customer_sk = (SELECT c_user_sk FROM another_customer_table WHERE c_parent_id = ch.c_customer_sk LIMIT 1) 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        w.ws_order_number,
        w.ws_item_sk,
        w.ws_ext_sales_price,
        w.ws_net_profit,
        w.ws_ship_date_sk,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales w
    JOIN 
        date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year IN (2022, 2023)
),
TotalSales AS (
    SELECT 
        SUM(sd.ws_ext_sales_price) AS total_sales,
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        SalesData sd
),
TopDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS demographic_count,
        SUM(td.total_sales) AS total_sales
    FROM 
        CustomerHierarchy ch
    JOIN 
        TotalSales td ON ch.c_customer_sk = td.ws_order_number
    JOIN 
        customer_demographics cd ON ch.cd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
    ORDER BY 
        total_sales DESC
)

SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count,
    d.total_sales,
    ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY d.total_sales DESC) AS ranking
FROM 
    TopDemographics d
WHERE 
    d.total_sales > (SELECT AVG(total_sales) FROM TopDemographics)
ORDER BY 
    d.cd_gender, d.total_sales DESC;
