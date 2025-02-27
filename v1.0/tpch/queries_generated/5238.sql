WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    GROUP BY s.s_suppkey, s.s_name, c.c_mktsegment
), RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT cs.c_custkey) AS distinct_customers,
    SUM(ro.total_revenue) AS total_revenue,
    AVG(rs.total_cost) AS avg_supplier_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN RankedSuppliers rs ON cs.c_nationkey = rs.s_suppkey
LEFT JOIN RecentOrders ro ON cs.c_custkey = ro.o_orderkey
WHERE rs.rank <= 5
GROUP BY r.r_name
ORDER BY total_revenue DESC;
