
WITH SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
ReturnsCTE AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
CombiningCTE AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales
    FROM 
        SalesCTE s
    LEFT JOIN 
        ReturnsCTE r ON s.ws_item_sk = r.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    c.market_id,
    c.total_quantity,
    c.total_sales,
    c.total_returns,
    c.net_sales,
    CASE 
        WHEN c.net_sales <= 0 THEN 'Loss'
        WHEN c.net_sales <= 100 THEN 'Low'
        WHEN c.net_sales BETWEEN 101 AND 500 THEN 'Medium'
        ELSE 'High'
    END AS performance_band
FROM 
    CombiningCTE c
JOIN 
    item i ON c.ws_item_sk = i.i_item_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (
        SELECT 
            c_current_cdemo_sk 
        FROM 
            customer 
        WHERE 
            c_customer_sk = (
                SELECT 
                    ws_bill_customer_sk 
                FROM 
                    web_sales 
                WHERE 
                    ws_item_sk = c.ws_item_sk 
                LIMIT 1
            )
    )
JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT 
            c_current_addr_sk 
        FROM 
            customer 
        WHERE 
            c_customer_sk = (
                SELECT 
                    ws_bill_customer_sk 
                FROM 
                    web_sales 
                WHERE 
                    ws_item_sk = c.ws_item_sk 
                LIMIT 1
            )
    )
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
ORDER BY 
    c.net_sales DESC;
