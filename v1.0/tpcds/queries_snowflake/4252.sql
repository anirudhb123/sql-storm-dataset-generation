
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM 
        web_sales
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
sales_summary AS (
    SELECT 
        psi.ws_item_sk,
        SUM(psi.ws_quantity) AS total_quantity,
        SUM(psi.ws_sales_price * psi.ws_quantity) AS total_sales,
        CASE 
            WHEN SUM(psi.ws_quantity) < 100 THEN 'Low'
            WHEN SUM(psi.ws_quantity) BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS sales_band
    FROM 
        web_sales psi
    GROUP BY 
        psi.ws_item_sk
),
items_with_returns AS (
    SELECT 
        ir.cr_item_sk,
        SUM(ir.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns ir
    GROUP BY 
        ir.cr_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ss.ws_item_sk,
    ss.total_quantity,
    ss.total_sales,
    ss.sales_band,
    COALESCE(iwr.total_returns, 0) AS total_returns
FROM 
    customer_info ci
JOIN 
    ranked_sales rs ON ci.c_customer_sk = (SELECT 
                                            ws_bill_customer_sk 
                                            FROM 
                                            web_sales 
                                            WHERE 
                                            ws_item_sk = rs.ws_item_sk 
                                            LIMIT 1)
JOIN 
    sales_summary ss ON rs.ws_item_sk = ss.ws_item_sk
LEFT JOIN 
    items_with_returns iwr ON rs.ws_item_sk = iwr.cr_item_sk
WHERE 
    rs.rank <= 5
ORDER BY 
    total_sales DESC, 
    total_quantity ASC;
