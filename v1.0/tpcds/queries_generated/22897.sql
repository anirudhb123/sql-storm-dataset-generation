
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0 
        AND ws_net_paid BETWEEN 1.00 AND 1000.00
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sales.total_net_profit,
        sales.order_count
    FROM 
        item
    JOIN 
        SalesData sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        sales.rank_profit <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) as customer_count
    FROM 
        customer cust
    JOIN 
        customer_demographics cd ON cust.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
ItemsPerCustomer AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(sales.total_net_profit) AS customer_profit,
        COUNT(DISTINCT sales.ws_item_sk) AS unique_items_purchased
    FROM 
        CustomerDemographics cd
    JOIN 
        web_sales sales ON sales.ws_bill_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    t.i_product_name,
    SUM(i.customer_profit) AS total_profit,
    AVG(i.unique_items_purchased) AS avg_unique_items,
    MAX(d.cd_gender) AS predominant_gender,
    STRING_AGG(CAST(d.cd_marital_status AS varchar), ', ') AS marital_status_reports,
    CASE 
        WHEN COUNT(t.order_count) > 0 THEN 'Sales Detected'
        ELSE 'No Sales'
    END AS sales_status
FROM 
    TopItems t
LEFT JOIN 
    ItemsPerCustomer i ON t.i_item_sk = i.cd_demo_sk
JOIN 
    CustomerDemographics d ON i.cd_demo_sk = d.cd_demo_sk
GROUP BY 
    t.i_product_name
HAVING 
    SUM(i.customer_profit) IS NOT NULL
    AND AVG(i.unique_items_purchased) > 1
ORDER BY 
    total_profit DESC
OFFSET 5 ROWS 
FETCH NEXT 10 ROWS ONLY;
