WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.nationkey = sh.nationkey
    WHERE sh.level < 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
ProductStatistics AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
LineItemStats AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_discount, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey, l.l_discount
),
RegionStats AS (
    SELECT r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    c.c_name,
    coalesce(cs.order_count, 0) AS order_count,
    ps.total_available,
    ps.avg_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY coalesce(cs.order_count, 0) ORDER BY ps.total_available DESC) AS rank,
    r.r_name,
    (SELECT COUNT(*) FROM SupplierHierarchy sh WHERE sh.nationkey = c.c_nationkey) AS supplier_level_count
FROM customer c
LEFT JOIN CustomerOrders cs ON c.c_custkey = cs.c_custkey
LEFT JOIN ProductStatistics ps ON ps.total_available > 1000
JOIN RegionStats r ON r.nation_count > 2
WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment IN ('AUTOMOBILE', 'FURNITURE')
ORDER BY order_count DESC, c.c_name
LIMIT 100;
