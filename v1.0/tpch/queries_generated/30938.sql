WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (
        SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderstatus = 'F' LIMIT 1
    ))
    WHERE sh.level < 5
),
TopCustomerOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY o.o_custkey
    HAVING total_spent > 10000
),
EligibleParts AS (
    SELECT p.p_partkey, p.p_retailprice, COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_retailprice
    HAVING total_available < 500
),
RegionSummary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    r.r_name,
    sh.s_name AS supplier_name,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    AVG(co.total_spent) AS avg_spent,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_retailprice, ')'), ', ') AS parts_info
FROM RegionSummary r
LEFT JOIN SupplierHierarchy sh ON r.nation_count > 1
JOIN TopCustomerOrders co ON co.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
LEFT JOIN EligibleParts p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 10.00)
GROUP BY r.r_name, sh.s_name
ORDER BY r.r_name, avg_spent DESC
LIMIT 10;
