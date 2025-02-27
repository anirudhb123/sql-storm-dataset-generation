
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
),
Ranked_Sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        Sales_CTE s
),
Customer_Purchase AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_sk
),
Average_Spending AS (
    SELECT 
        AVG(total_spent) AS avg_spent
    FROM 
        Customer_Purchase
),
Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cu.purchase_count,
        cu.total_spent,
        CASE 
            WHEN cu.total_spent < a.avg_spent THEN 'Below Average'
            ELSE 'Above Average'
        END AS spending_category
    FROM 
        customer_demographics cd
    JOIN 
        Customer_Purchase cu ON cd.cd_demo_sk = cu.c_customer_sk
    CROSS JOIN 
        Average_Spending a
),
Final_Report AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        SUM(d.purchase_count) AS total_customers,
        SUM(d.total_spent) AS total_revenue,
        AVG(d.purchase_count) AS avg_purchase_per_customer,
        AVG(d.total_spent) AS avg_spent_per_customer
    FROM 
        Customer_Demographics d
    GROUP BY 
        d.cd_gender, d.cd_marital_status
)
SELECT 
    r.cd_gender,
    r.cd_marital_status,
    r.total_customers,
    r.total_revenue,
    r.avg_purchase_per_customer,
    r.avg_spent_per_customer,
    CASE 
        WHEN r.avg_spent_per_customer IS NULL OR r.avg_spent_per_customer > 1000 THEN 'High Value Segment'
        ELSE 'Low Value Segment'
    END AS customer_segment
FROM 
    Final_Report r
LEFT JOIN 
    warehouse w ON w.w_warehouse_sk IN (SELECT inv.inv_warehouse_sk FROM inventory inv JOIN item i ON inv.inv_item_sk = i.i_item_sk WHERE i.i_current_price > 50)
WHERE 
    r.total_revenue IS NOT NULL
ORDER BY 
    r.total_revenue DESC;
