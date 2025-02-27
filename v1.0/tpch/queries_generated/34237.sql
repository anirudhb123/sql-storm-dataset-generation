WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_orderstatus, o_totalprice, 1 AS lvl
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus, o.o_totalprice, oh.lvl + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
    WHERE o.o_orderstatus = 'O'
),
SupplierPerformance AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT p.p_name, p.p_brand, p.p_type,
       COALESCE(n.n_name, 'Unknown') AS nation_name,
       sp.total_available, sp.total_cost,
       oh.o_orderdate, oh.o_totalprice,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY oh.o_orderdate DESC) AS order_rank
FROM part p
LEFT JOIN SupplierPerformance sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN nation n ON sp.ps_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = p.p_partkey LIMIT 1) 
LEFT JOIN OrderHierarchy oh ON oh.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
WHERE (sp.total_available > 50 OR n.n_name IS NULL)
  AND (YEAR(oh.o_orderdate) >= 2020)
ORDER BY p.p_brand, order_rank
LIMIT 100;
