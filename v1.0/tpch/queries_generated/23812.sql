WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           LEAD(p.p_retailprice) OVER (ORDER BY p.p_partkey) AS next_retailprice
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT SIZE 
                       FROM (SELECT CASE 
                                    WHEN p_size < 10 THEN 'SMALL' 
                                    WHEN p_size BETWEEN 10 AND 20 THEN 'MEDIUM' 
                                    ELSE 'LARGE' END AS SIZE 
                               FROM part) AS subquery)
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
SupplierSummary AS (
    SELECT s.s_nationkey, SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
)
SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       MAX(ol.total_revenue) AS max_revenue, 
       SUM(COALESCE(ss.total_availqty, 0)) AS total_availqty,
       STRING_AGG(DISTINCT fp.p_name || ' (' || fp.p_retailprice || ')', '; ') AS part_names
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN OrderDetails ol ON ol.o_orderkey = s.s_suppkey
LEFT JOIN SupplierSummary ss ON ss.s_nationkey = n.n_nationkey
LEFT JOIN FilteredParts fp ON fp.p_partkey = (SELECT ps.ps_partkey 
                                                FROM partsupp ps 
                                                WHERE ps.ps_supplycost = (SELECT MIN(ps2.ps_supplycost) 
                                                                           FROM partsupp ps2 
                                                                           WHERE ps2.ps_partkey = fp.p_partkey))
WHERE n.n_nationkey IN (SELECT DISTINCT n_nationkey FROM nation WHERE n_comment IS NOT NULL
                         AND n_name NOT LIKE '%land')
GROUP BY n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 3
ORDER BY total_availqty DESC, max_revenue DESC;
