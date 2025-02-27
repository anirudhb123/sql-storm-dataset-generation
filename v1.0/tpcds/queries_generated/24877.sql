
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws_net_paid) IS NOT NULL
),
FrequentItems AS (
    SELECT 
        il.i_item_id,
        SUM(il.quantity) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY SUM(il.quantity) DESC) AS rank
    FROM (
        SELECT 
            ws_item_sk,
            ws_quantity AS quantity
        FROM 
            web_sales
        UNION ALL
        SELECT 
            cs_item_sk,
            cs_quantity AS quantity
        FROM 
            catalog_sales
        UNION ALL
        SELECT 
            ss_item_sk,
            ss_quantity AS quantity
        FROM 
            store_sales
    ) il
    GROUP BY 
        il.i_item_id
),
MaxSpent AS (
    SELECT 
        c.c_customer_sk,
        MAX(total_spent) AS max_spent
    FROM 
        CustomerStats c
    GROUP BY 
        c.c_customer_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_zip DESC) AS address_rank
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state = 'CA'
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_spent,
    fi.i_item_id,
    fi.total_quantity,
    CASE 
        WHEN fi.total_quantity IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status,
    ad.ca_address_id
FROM 
    CustomerStats cs
JOIN 
    FrequentItems fi ON cs.c_customer_sk = fi.i_item_id
LEFT JOIN 
    MaxSpent ms ON cs.c_customer_sk = ms.c_customer_sk 
LEFT JOIN 
    AddressDetails ad ON cs.c_customer_sk = ad.ca_address_id
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
    AND ad.address_rank <= 5
ORDER BY 
    cs.total_orders DESC, cs.total_spent DESC, fi.total_quantity DESC;
