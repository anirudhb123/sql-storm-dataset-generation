WITH RECURSIVE SupplierRanking AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty * l.l_quantity) AS total_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT s.*, RANK() OVER (ORDER BY total_availqty DESC) AS rank
    FROM SupplierRanking s
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(os.total_revenue) AS total_revenues,
    COALESCE(MAX(rs.rank), 0) AS highest_supplier_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderSummary os ON os.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
LEFT JOIN RankedSuppliers rs ON rs.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_size > 10
    )
)
WHERE c.c_acctbal IS NOT NULL 
AND os.total_revenue IS NOT NULL
GROUP BY r.r_name, n.n_name
ORDER BY total_revenues DESC, num_customers DESC;
