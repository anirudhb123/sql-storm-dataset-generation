
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 0 AS Level
    FROM orders o
    WHERE o.o_orderstatus = 'O' 
      AND o.o_orderdate >= '1997-01-01' 
      AND o.o_orderdate < '1997-10-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.Level + 1 
    FROM orders o
    JOIN OrderHierarchy oh ON oh.o_orderkey = o.o_orderkey 
    WHERE o.o_orderstatus = 'F'
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS part_rank,
    CONCAT('Part: ', p.p_name, ' - Price: ', p.p_retailprice) AS part_info
FROM part p
LEFT OUTER JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT OUTER JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT OUTER JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_retailprice > 100.00 
  AND (n.n_name IS NULL OR n.n_name <> 'USA')
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
HAVING SUM(l.l_quantity) > 0
ORDER BY revenue DESC
LIMIT 10;
