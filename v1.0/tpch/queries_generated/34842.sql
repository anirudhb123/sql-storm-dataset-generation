WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, o.o_totalprice, 1 AS level
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, oh.o_totalprice, level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)
, SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    pd.total_cost,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY pd.total_cost DESC) AS rank,
    COALESCE(n.n_name, 'Unknown') AS supplier_nation,
    SUBSTRING(p.p_comment FROM 1 FOR 20) AS truncated_comment,
    CASE 
        WHEN l.l_discount > 0.1 THEN 'High Discount'
        ELSE 'Normal Discount'
    END AS discount_category
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierDetails pd ON l.l_suppkey = pd.s_suppkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_size BETWEEN 1 AND 20
  AND (l.l_returnflag = 'N' OR l.l_linestatus = 'O')
  AND NOT EXISTS (
      SELECT 1 FROM lineitem l2 
      WHERE l2.l_orderkey = l.l_orderkey AND l2.l_returnflag = 'Y'
  )
ORDER BY p.p_partkey, rank DESC;
