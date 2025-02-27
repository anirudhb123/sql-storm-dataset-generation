
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_dow IN (1, 2, 3, 4, 5) -- Monday to Friday
),
Refunds AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_refunds
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
SalesByAddress AS (
    SELECT 
        ca.ca_address_id,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_id
)
SELECT 
    RANK() OVER (ORDER BY SUM(total_sales) DESC) AS sales_rank,
    a.ca_address_id,
    COALESCE(SUM(s.total_sales), 0) AS sales_amount,
    COALESCE(r.total_refunds, 0) AS refunds,
    (COALESCE(SUM(s.total_sales), 0) - COALESCE(r.total_refunds, 0)) AS net_sales,
    CASE WHEN COALESCE(SUM(s.total_sales), 0) > 0 THEN 
        (COALESCE(SUM(s.total_sales), 0) - COALESCE(r.total_refunds, 0)) / COALESCE(SUM(s.total_sales), 0) 
    ELSE 
        NULL 
    END AS refund_ratio
FROM 
    SalesByAddress s
LEFT JOIN 
    customer_address a ON s.ca_address_id = a.ca_address_id
LEFT JOIN 
    Refunds r ON r.sr_returning_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales) 
GROUP BY 
    a.ca_address_id, r.total_refunds
ORDER BY 
    sales_rank
FETCH FIRST 10 ROWS ONLY;
