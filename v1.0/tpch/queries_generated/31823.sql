WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_nationkey IN (
        SELECT n_nationkey
        FROM nation
        WHERE n_name = 'United States'
    )
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey != sh.s_suppkey
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost,
           COUNT(DISTINCT p.p_brand) AS brand_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderStats AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT r.r_name AS region_name,
       n.n_name AS nation_name,
       s.s_name AS supplier_name,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       SUM(ps.ps_availqty) AS total_available_parts,
       COUNT(DISTINCT p.p_partkey) AS unique_parts,
       MAX(po.total_price) AS max_order_value
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN PartStats p ON ps.ps_partkey = p.p_partkey
LEFT JOIN OrderStats po ON s.s_suppkey = po.o_orderkey
WHERE r.r_name IS NOT NULL
  AND p.brand_count > 2
GROUP BY r.r_name, n.n_name, s.s_name
HAVING SUM(ps.ps_supplycost) > 1000.00
ORDER BY order_count DESC
LIMIT 10;
