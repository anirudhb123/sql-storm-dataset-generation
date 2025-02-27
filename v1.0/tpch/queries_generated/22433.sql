WITH RECURSIVE NationalCustomer AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
  
    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN NationalCustomer nc ON nc.n_regionkey = n.n_regionkey
    WHERE c.c_acctbal > nc.c_acctbal
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost) > (
        SELECT AVG(SUM(ps_inner.ps_supplycost)) 
        FROM partsupp ps_inner
        GROUP BY ps_inner.ps_suppkey
    )
), 
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), 
SupplierRankings AS (
    SELECT s.s_name, DENSE_RANK() OVER (ORDER BY ts.total_supplycost DESC) AS rank
    FROM supplier s
    JOIN TopSuppliers ts ON s.s_suppkey = ts.ps_suppkey
)
SELECT nac.c_name, nac.c_acctbal, sr.s_name, od.total_price
FROM NationalCustomer nac
LEFT JOIN OrderDetails od ON nac.c_custkey = od.o_orderkey
LEFT JOIN SupplierRankings sr ON od.o_orderkey = (
    SELECT l.l_orderkey 
    FROM lineitem l
    WHERE l.l_suppkey = (
        SELECT s.s_suppkey 
        FROM supplier s
        JOIN TopSuppliers ts ON s.s_suppkey = ts.ps_suppkey
        ORDER BY ts.total_supplycost DESC
        LIMIT 1
    )
    AND l.l_discount > 0.05
)
WHERE od.total_price IS NOT NULL 
  AND nac.c_acctbal > COALESCE((SELECT MAX(c.c_acctbal) FROM customer c WHERE c.c_nationkey IS NULL), 0)
ORDER BY nac.c_acctbal DESC, sr.rank;
