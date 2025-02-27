
WITH Ranked_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
Top_Items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        Ranked_Sales.total_quantity,
        Ranked_Sales.total_sales
    FROM 
        Ranked_Sales
    JOIN 
        item ON Ranked_Sales.ws_item_sk = item.i_item_sk
    WHERE 
        Ranked_Sales.sales_rank <= 5
),
Customer_Spend AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_spend
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
Aggregate_Spend AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        AVG(cs.total_spend) AS average_spending
    FROM 
        Customer_Spend cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    a.cd_gender,
    a.customer_count,
    a.average_spending
FROM 
    Top_Items ti
CROSS JOIN 
    Aggregate_Spend a
ORDER BY 
    ti.total_sales DESC, a.average_spending ASC;
