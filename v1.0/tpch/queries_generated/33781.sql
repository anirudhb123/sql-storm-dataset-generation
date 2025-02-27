WITH RECURSIVE SupplierRank AS (
    SELECT s_suppkey, s_name, s_acctbal,
           RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, n.n_name, s.s_acctbal
    FROM SupplierRank s
    JOIN nation n ON s.n_nationkey = n.n_nationkey
    WHERE s.rank <= 5
),
OrderLineSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT ps.ps_partkey, p.p_name, 
       COALESCE((SELECT SUM(ps_supplycost * ps_availqty) 
                 FROM partsupp ps 
                 WHERE ps.ps_partkey = p.p_partkey), 0) AS total_supplycost,
       COUNT(DISTINCT CASE WHEN o.o_orderstatus = 'F' THEN o.o_orderkey END) AS fulfilled_orders,
       SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice END) AS fulfilled_revenue,
       RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS revenue_rank,
       cs.order_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN CustomerOrderCount cs ON cs.c_custkey = o.o_custkey
JOIN TopSuppliers ts ON ts.s_suppkey = l.l_suppkey
GROUP BY p.p_partkey, p.p_name, cs.order_count
HAVING total_supplycost > 1000
ORDER BY revenue_rank;
