WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus <> 'F'
    GROUP BY c.c_custkey
), PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_suppkey) AS supplier_count, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
), RankedLineItems AS (
    SELECT l.*, 
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
    WHERE l.l_discount > 0.2
)
SELECT 
    r.r_name,
    SUM(COALESCE(cos.total_spent, 0)) AS total_spent_by_customers,
    SUM(ps.supplier_count) AS total_suppliers,
    AVG(pli.l_extendedprice) AS avg_extended_price
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN CustomerOrderStats cos ON cos.c_custkey = c.c_custkey
LEFT JOIN PartSupplierInfo ps ON ps.p_partkey IN (
    SELECT DISTINCT l.l_partkey
    FROM RankedLineItems l
    WHERE l.price_rank <= 5 AND l.l_returnflag = 'N'
)
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(COALESCE(cos.total_spent, 0)) > 10000
ORDER BY total_spent_by_customers DESC;
