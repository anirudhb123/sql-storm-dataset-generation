
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(COALESCE(ss.ss_sales_price, 0) - ss.ss_ext_discount_amt) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ca.state ORDER BY SUM(COALESCE(ss.ss_sales_price, 0) - ss.ss_ext_discount_amt) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, ca.state
), StateAverage AS (
    SELECT 
        ca.state, 
        AVG(total_sales) AS average_sales
    FROM 
        RankedCustomerSales rcs
    JOIN 
        customer_address ca ON rcs.c_customer_id = ca.ca_address_sk
    GROUP BY 
        ca.state
), SalesComparison AS (
    SELECT 
        rcs.c_customer_id,
        rcs.total_sales,
        sa.average_sales,
        CASE 
            WHEN rcs.total_sales > sa.average_sales THEN 'Above Average'
            WHEN rcs.total_sales = sa.average_sales THEN 'Average'
            ELSE 'Below Average'
        END AS sales_comparison
    FROM 
        RankedCustomerSales rcs
    JOIN 
        StateAverage sa ON rcs.sales_rank = 1 AND sa.state = (SELECT state FROM customer_address WHERE ca_address_sk = rcs.c_customer_id LIMIT 1)
)
SELECT 
    s.comparison_state, 
    COUNT(*) AS customer_count,
    SUM(total_sales) AS total_sales_amount,
    MAX(total_sales) AS max_sales,
    MIN(total_sales) AS min_sales
FROM (
    SELECT 
        CASE 
            WHEN sales_comparison = 'Above Average' THEN 'Above Average'
            WHEN sales_comparison = 'Average' THEN 'Average'
            ELSE 'Below Average'
        END AS comparison_state,
        total_sales
    FROM 
        SalesComparison
) AS s
GROUP BY 
    s.comparison_state
HAVING 
    COUNT(*) > 10
ORDER BY 
    customer_count DESC
LIMIT 5;
