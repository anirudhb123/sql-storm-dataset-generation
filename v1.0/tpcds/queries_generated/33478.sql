
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
Top_Sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_sales,
        ROW_NUMBER() OVER (ORDER BY sales.total_sales DESC) AS rank
    FROM 
        Sales_CTE sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales_rank <= 5
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Customer_Status AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_age_group,
        SUM(cs.total_spent) AS total_spending
    FROM 
        Customer_Sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_age_group
),
Sales_Performance AS (
    SELECT 
        t.ws_item_sk,
        SUM(t.ws_quantity) AS total_quantity_sold,
        SUM(t.ws_net_profit) AS total_net_profit
    FROM 
        web_sales t
    WHERE 
        t.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        t.ws_item_sk
)
SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    COALESCE(cs.total_spending, 0) AS customer_total_spending,
    COALESCE(sp.total_net_profit, 0) AS item_net_profit,
    ts.total_quantity,
    ts.total_sales
FROM 
    Top_Sales ts
LEFT JOIN 
    Customer_Status cs ON ts.i_item_id = cs.cd_age_group 
LEFT JOIN 
    Sales_Performance sp ON ts.ws_item_sk = sp.ws_item_sk
WHERE 
    ts.total_sales > (SELECT AVG(total_sales) FROM Top_Sales)
ORDER BY 
    ts.total_sales DESC;
