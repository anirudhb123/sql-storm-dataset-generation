WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > (
        SELECT AVG(ps2.ps_availqty) FROM partsupp ps2 WHERE ps2.ps_partkey = p.p_partkey
    )
),
HighValueLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(sh.level, 0) AS supplier_level,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts,
    SUM(COALESCE(hvli.total_line_value, 0)) AS high_value_total
FROM CustomerOrders co
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = co.custkey
LEFT JOIN PartSupplier p ON p.p_name LIKE '%' || co.c_name || '%'
LEFT JOIN HighValueLineItems hvli ON hvli.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
GROUP BY co.c_custkey, co.c_name, sh.level
HAVING SUM(COALESCE(hvli.total_line_value, 0)) IS NOT NULL AND COUNT(DISTINCT p.p_partkey) > 5
ORDER BY high_value_total DESC, co.c_custkey
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
