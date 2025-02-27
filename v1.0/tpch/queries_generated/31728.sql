WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, h.level + 1
    FROM orders oh
    JOIN OrderHierarchy h ON oh.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal = 
        (SELECT MAX(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = h.n_nationkey))
    WHERE h.level < 3
)
, SupplierAggregation AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COALESCE(su.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(su.total_supply_cost, 0) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) OVER (PARTITION BY n.n_nationkey ORDER BY r.r_regionkey) AS avg_order_price,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS order_rank
FROM part p
LEFT JOIN supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierAggregation su ON p.p_partkey = su.ps_partkey
WHERE (s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000) 
  AND (n.n_comment NOT LIKE '%foreign%' OR n.n_comment IS NULL)
GROUP BY p.p_partkey, p.p_name, p.p_brand, r.r_name, n.n_name, s.s_name, su.total_avail_qty, su.total_supply_cost
ORDER BY order_rank, r.r_name;
