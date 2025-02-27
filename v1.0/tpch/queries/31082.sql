WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    GROUP BY o.o_custkey
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)

SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE WHEN o.order_count > 5 THEN o.total_spent ELSE 0 END) AS high_value_customers,
    AVG(ps.ps_supplycost) AS average_cost,
    STRING_AGG(DISTINCT sub.c_name, ', ') AS customer_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN OrderSummary o ON s.s_suppkey = o.o_custkey
LEFT JOIN PartSupplier ps ON ps.rn = 1
LEFT JOIN customer sub ON sub.c_nationkey = n.n_nationkey
WHERE EXISTS (
    SELECT 1
    FROM lineitem l
    WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = o.o_custkey)
    AND l.l_discount > 0.1
)
GROUP BY r.r_name
ORDER BY supplier_count DESC, average_cost NULLS LAST
LIMIT 10;
