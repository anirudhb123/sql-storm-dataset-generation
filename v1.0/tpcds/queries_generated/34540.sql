
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_item_sk, 
        ss_ticket_number, 
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk, 
        ss_ticket_number
    HAVING 
        SUM(ss_net_paid) > 100 
), 
address_summary AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IS NOT NULL 
    GROUP BY 
        ca_state
), 
returns_summary AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
final_summary AS (
    SELECT 
        i.i_item_id,
        s.total_sales,
        asum.customer_count,
        asum.avg_dependents,
        r.total_returns,
        r.total_return_amount,
        CASE 
            WHEN r.total_returns IS NULL THEN 0
            ELSE r.total_returns 
        END AS return_adjusted
    FROM 
        (SELECT 
             item.i_item_sk, 
             i.i_item_id, 
             SUM(ss_ext_sales_price) AS total_sales
         FROM 
             item i
         LEFT JOIN 
             store_sales ss ON i.i_item_sk = ss.ss_item_sk
         GROUP BY 
             item.i_item_sk, i.i_item_id) s
    LEFT JOIN 
        returns_summary r ON s.i_item_sk = r.sr_item_sk
    LEFT JOIN 
        address_summary asum ON 1=1
)

SELECT 
    f.i_item_id,
    f.total_sales,
    f.customer_count,
    f.avg_dependents,
    COALESCE(f.total_returns, 0) AS total_returns,
    f.return_adjusted
FROM 
    final_summary f
WHERE 
    f.total_sales > 5000 OR f.customer_count > 100
ORDER BY 
    f.total_sales DESC, f.customer_count DESC
LIMIT 10;
