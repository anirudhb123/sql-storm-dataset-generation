WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_custkey AS customer_key,
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
nation_sales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(s.s_acctbal), 0) AS total_account_balance,
        COUNT(DISTINCT sh.customer_key) AS num_customers,
        SUM(sh.total_sales) AS total_sales_per_nation
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN sales_hierarchy sh ON sh.customer_key IN (
        SELECT DISTINCT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey
    )
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.total_account_balance,
    ns.num_customers,
    ns.total_sales_per_nation,
    ROW_NUMBER() OVER (ORDER BY ns.total_sales_per_nation DESC) AS sales_rank
FROM nation_sales ns
WHERE ns.total_sales_per_nation IS NOT NULL
ORDER BY ns.total_sales_per_nation DESC
LIMIT 10
UNION ALL
SELECT 
    'OVERALL_TOTAL' AS n_name,
    NULL AS total_account_balance,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales_per_nation
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.o_orderkey
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31';
