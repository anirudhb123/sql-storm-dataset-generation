
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ext_sales_price DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
), customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        h.hd_income_band_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_first_name
            ELSE 'Ms. ' || c.c_first_name
        END AS full_name
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
), sales_analysis AS (
    SELECT 
        cr.cr_order_number,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_returned_items
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk IS NOT NULL
    GROUP BY 
        cr.cr_order_number
), combined_data AS (
    SELECT 
        c.full_name,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        SUM(COALESCE(rs.ws_ext_sales_price, 0)) AS total_web_sales,
        COALESCE(sa.total_returns, 0) AS total_catalog_returns
    FROM 
        customer_details c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        ranked_sales rs ON ss.ss_ticket_number = rs.ws_order_number
    LEFT JOIN 
        sales_analysis sa ON rs.ws_order_number = sa.cr_order_number
    WHERE 
        (c.hd_income_band_sk IS NOT NULL AND c.hd_income_band_sk <> 0)
    GROUP BY 
        c.full_name
)
SELECT 
    cd.full_name,
    cd.total_sales,
    cd.total_web_sales,
    cd.total_catalog_returns,
    CASE 
        WHEN cd.total_sales > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM 
    combined_data cd
WHERE 
    cd.total_sales >= (SELECT AVG(total_sales) FROM combined_data WHERE total_sales > 0)
    OR cd.total_web_sales > (
        SELECT COALESCE(AVG(total_web_sales), 0) FROM combined_data WHERE total_web_sales IS NOT NULL
    )
ORDER BY 
    customer_status DESC, 
    cd.total_web_sales DESC;
