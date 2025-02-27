
WITH RecursiveSalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
AddressInfo AS (
    SELECT
        ca_address_id,
        ca_city,
        ca_state,
        ca_country,
        CASE 
            WHEN ca_state IN ('CA', 'TX') THEN 'High Demand'
            WHEN ca_state IN ('NY', 'FL') THEN 'Medium Demand'
            ELSE 'Low Demand' 
        END AS demand_category
    FROM
        customer_address
), 
SalesAnalysis AS (
    SELECT 
        item.i_item_id,
        SUM(COALESCE(ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_price,
        ai.demand_category
    FROM 
        RecursiveSalesCTE rsc
    JOIN 
        item ON rsc.ws_item_sk = item.i_item_sk
    LEFT JOIN 
        AddressInfo ai ON item.i_item_sk = (SELECT i_item_sk FROM store_sales 
                                             WHERE ss_ticket_number = rsc.ws_order_number 
                                             LIMIT 1)
    GROUP BY 
        item.i_item_id, ai.demand_category
),
TopSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY demand_category ORDER BY total_sales DESC) AS rank_sales
    FROM 
        SalesAnalysis
)
SELECT 
    *
FROM 
    TopSales
WHERE 
    rank_sales <= 5
ORDER BY 
    demand_category, total_sales DESC;
