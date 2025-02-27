
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank,
        ws.ws_sales_price,
        ws.ws_net_paid,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'Price Not Available'
            ELSE 'Price Available'
        END AS price_availability,
        DENSE_RANK() OVER(ORDER BY ws.ws_net_paid DESC) AS price_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_month BETWEEN 1 AND 6
), FilteredSales AS (
    SELECT
        rs.ws_item_sk,
        SUM(rs.ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rank = 1 OR (rs.ws_sales_price IS NOT NULL AND rs.ws_sales_price < 25)
    GROUP BY 
        rs.ws_item_sk
), ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(f.total_net_paid, 0) AS total_net_paid,
        COALESCE(f.sales_count, 0) AS sales_count,
        i.i_current_price,
        CASE 
            WHEN f.sales_count = 0 THEN 'No Sales'
            ELSE 'Sales Recorded'
        END AS sales_status
    FROM 
        item i
    LEFT JOIN 
        FilteredSales f ON i.i_item_sk = f.ws_item_sk
), AddressStats AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(cd.cd_dep_count) AS average_dependent_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'TX') 
    GROUP BY 
        ca.ca_state
)
SELECT 
    ii.i_item_id,
    ii.i_item_desc,
    ii.total_net_paid,
    ii.sales_count,
    ii.sales_status,
    as.ca_state,
    as.unique_customers,
    as.average_dependent_count
FROM 
    ItemInfo ii
FULL OUTER JOIN 
    AddressStats as ON ii.sales_count = as.unique_customers
WHERE 
    (ii.total_net_paid > 100 OR as.average_dependent_count IS NULL)
AND
    (ii.sales_status = 'Sales Recorded' OR as.ca_state IS NOT NULL)
ORDER BY 
    ii.total_net_paid DESC NULLS LAST, as.average_dependent_count DESC;
