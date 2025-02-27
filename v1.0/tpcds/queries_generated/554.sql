
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_moy IN (5, 6, 7) 
    GROUP BY 
        ws.ws_item_sk
), 
top_item_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        ranked_sales rs
    WHERE 
        rs.rn = 1
), 
customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        count(DISTINCT o.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales o ON c.c_customer_sk = o.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)

SELECT 
    td.c_customer_id,
    td.cd_gender,
    td.cd_marital_status,
    td.cd_credit_rating,
    si.total_sales,
    si.total_quantity,
    case 
        when cp.purchase_count > 0 then 'Frequent'
        when cp.purchase_count = 0 then 'Infrequent'
        else 'Unknown'
    end AS customer_segment,
    CASE 
        WHEN si.total_sales IS NOT NULL THEN ROUND(si.total_sales * 1.05, 2) 
        ELSE 0 
    END AS estimated_final_sales
FROM 
    top_item_sales si 
FULL OUTER JOIN 
    customer_data td ON si.ws_item_sk = td.c_customer_id
LEFT JOIN 
    customer_data cp ON td.c_customer_id = cp.c_customer_id
WHERE 
    (td.cd_credit_rating = 'High' OR td.cd_credit_rating IS NULL)
ORDER BY 
    estimated_final_sales DESC, td.cd_gender;
