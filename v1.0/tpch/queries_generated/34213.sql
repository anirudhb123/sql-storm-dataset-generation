WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O' AND oh.level < 5
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS orders_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_name, 
    s.s_name,
    COALESCE(cs.orders_count, 0) AS orders_count,
    COALESCE(cs.total_spent, 0) AS total_spent,
    AVG(sp.avg_supply_cost) AS avg_supply_cost,
    COUNT(oh.o_orderkey) AS order_level_count
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN CustomerStats cs ON s.s_nationkey = cs.c_custkey
LEFT JOIN OrderHierarchy oh ON oh.o_orderkey = ps.ps_partkey
JOIN NationRegion nr ON s.s_nationkey = nr.n_nationkey
WHERE p.p_retailprice > 500.00
  AND s.s_acctbal IS NOT NULL
  AND (s.s_comment LIKE '%quality%' OR s.s_comment IS NULL)
GROUP BY p.p_name, s.s_name, cs.orders_count, cs.total_spent, nr.region_name
ORDER BY avg_supply_cost DESC, total_spent DESC
LIMIT 100;
