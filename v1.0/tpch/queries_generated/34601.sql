WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < 10000
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT
    p.p_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    MAX(od.total_revenue) AS max_order_revenue,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE p.p_type LIKE '%brass%' 
AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1)
AND l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY p.p_name
HAVING COUNT(l.l_quantity) > 10
ORDER BY returned_quantity DESC, avg_supplier_balance ASC;
