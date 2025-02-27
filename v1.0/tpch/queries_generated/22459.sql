WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderstatus, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderstatus, oh.o_totalprice * 0.9, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderkey < oh.o_orderkey)
    WHERE oh.level < 5
), 
PartSupplierPrice AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, COALESCE(NULLIF(SUM(l.l_extendedprice * (1 - l.l_discount)), 0), 0) AS total_revenue
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey, p.p_name, ps.ps_supplycost
),
SupplierNation AS (
    SELECT s.s_suppkey, n.n_name AS supplier_nation, COUNT(*) AS supplier_count
    FROM supplier s
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, n.n_name
    HAVING COUNT(*) > 1
)
SELECT oh.o_orderkey, oh.o_orderdate, oh.o_orderstatus, 
       psp.p_name, psp.total_revenue, 
       sn.supplier_nation, sn.supplier_count,
       ROW_NUMBER() OVER(PARTITION BY oh.o_orderkey ORDER BY psp.total_revenue DESC) AS rank
FROM OrderHierarchy oh
JOIN PartSupplierPrice psp ON psp.total_revenue > (SELECT AVG(total_revenue) FROM PartSupplierPrice)  
LEFT JOIN SupplierNation sn ON psp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp))
WHERE w_position IS NOT NULL
ORDER BY oh.o_orderkey, psp.total_revenue DESC;
