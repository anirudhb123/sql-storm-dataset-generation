WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
TopParts AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_available_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 100
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
        COUNT(l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(od.revenue) AS total_revenue,
    SUM(s.s_acctbal) AS total_supplier_balance
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank <= 5
JOIN TopParts tp ON tp.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN orders o ON s.s_suppkey = o.o_custkey
JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
JOIN customer cs ON o.o_custkey = cs.c_custkey
GROUP BY r.r_name
ORDER BY total_revenue DESC;