WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL
), 

RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -12, GETDATE())
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
), 

CustomerStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)

SELECT 
    r.r_name,
    COALESCE(SUM(CASE WHEN cs.order_count > 0 THEN cs.total_spent ELSE 0 END), 0) AS total_spent_by_customers,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    MAX(cs.avg_spent) AS max_average_spent,
    STRING_AGG(DISTINCT p.p_name, ', ') AS parts_details
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
LEFT JOIN CustomerStats cs ON c.c_custkey = cs.c_custkey
LEFT JOIN RankedSuppliers rs ON rs.rn = 1 -- Get the top supplier per part
LEFT JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE r.r_comment IS NOT NULL
GROUP BY r.r_name
HAVING SUM(COALESCE(ro.total_revenue, 0)) > 0 OR COUNT(DISTINCT rs.s_suppkey) > 0
ORDER BY r.r_name DESC
