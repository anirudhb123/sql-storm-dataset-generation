
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2459654  -- Filtering by a date range
    GROUP BY 
        ws_item_sk
),
Top_Selling_Items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(sales.total_sales, 0) AS total_sales
    FROM 
        item
    LEFT JOIN 
        Sales_CTE sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        sales.sales_rank <= 5 OR sales.sales_rank IS NULL
),
Customer_Income AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN h.hd_income_band_sk IS NOT NULL THEN 
                CASE 
                    WHEN h.hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low'
                    WHEN h.hd_income_band_sk BETWEEN 4 AND 6 THEN 'Medium'
                    ELSE 'High'
                END
            ELSE 'Unknown'
        END AS income_level
    FROM 
        customer c
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
Sales_By_Income AS (
    SELECT 
        ci.income_level,
        SUM(web.ws_net_paid_inc_tax) AS total_spent
    FROM 
        web_sales web
    JOIN 
        Customer_Income ci ON web.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        ci.income_level
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_sales,
    si.income_level,
    COALESCE(sbi.total_spent, 0) AS income_spent
FROM 
    Top_Selling_Items ti
LEFT JOIN 
    Sales_By_Income sbi ON sbi.income_level = 
    (CASE 
        WHEN ti.total_sales = (SELECT MAX(total_sales) FROM Top_Selling_Items) THEN 'High'
        ELSE 'Low'
    END)
ORDER BY 
    ti.total_sales DESC, income_spent DESC;
