
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price IS NOT NULL
),
TotalSales AS (
    SELECT
        item.i_item_id,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales
    FROM
        item
    LEFT JOIN
        RankedSales rs ON item.i_item_sk = rs.ws_item_sk AND rs.rank_sales <= 5
    LEFT JOIN
        web_sales ws ON rs.ws_item_sk = ws.ws_item_sk AND rs.ws_order_number = ws.ws_order_number
    GROUP BY
        item.i_item_id
),
TopSellingItems AS (
    SELECT
        ts.i_item_id,
        ts.total_sales,
        DENSE_RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM
        TotalSales ts
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ci.ca_city,
    t.total_sales,
    CASE 
        WHEN t.total_sales IS NULL THEN 'No Sales'
        WHEN t.total_sales > 10000 THEN 'High Roller'
        ELSE 'Average Joe' 
    END AS sales_category
FROM
    customer c
LEFT JOIN
    customer_address ci ON c.c_current_addr_sk = ci.ca_address_sk
LEFT JOIN
    TopSellingItems t ON t.i_item_id IN (
        SELECT
            DISTINCT i.i_item_id 
        FROM 
            item i
        JOIN 
            web_sales ws ON i.i_item_sk = ws.ws_item_sk
        WHERE 
            ws.ws_quantity >= (SELECT AVG(ws2.ws_quantity) FROM web_sales ws2) 
        AND 
            i.i_item_id IS NOT NULL
    )
WHERE
    c.c_birth_country IS NOT NULL
    AND ci.ca_state IN ('NY', 'CA', 'TX')
    AND EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_item_sk = t.i_item_id
        AND ss.ss_net_profit > (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2)
    )
ORDER BY
    sales_category,
    c.c_last_name;
