WITH RECURSIVE regional_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_supplier_balance,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
    
    UNION ALL
    
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(COALESCE(s.s_acctbal, 0)) + rs.total_supplier_balance AS total_supplier_balance,
        COUNT(DISTINCT n.n_nationkey) + rs.nation_count AS nation_count
    FROM region r
    JOIN regional_summary rs ON r.r_regionkey = rs.r_regionkey
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE rs.nation_count < 5
    GROUP BY r.r_regionkey, r.r_name
),
filtered_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' AND l.l_shipdate > '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
top_customers AS (
    SELECT DISTINCT c.c_custkey, c.c_name
    FROM customer c
    JOIN filtered_orders fo ON c.c_custkey = fo.o_custkey
    WHERE fo.revenue_rank <= 5
)
SELECT 
    r.r_name,
    SUM(rs.total_supplier_balance) AS total_balances,
    COUNT(DISTINCT tc.c_custkey) AS top_customer_count
FROM regional_summary rs
JOIN top_customers tc ON tc.c_custkey IN (
    SELECT DISTINCT c.c_custkey FROM customer c WHERE c.c_nationkey IN (
        SELECT n.n_nationkey FROM nation n
        JOIN region r ON n.n_regionkey = r.r_regionkey
        WHERE r.r_name IS NOT NULL
    )
)
GROUP BY r.r_name
HAVING total_balances IS NOT NULL
ORDER BY total_balances DESC;
