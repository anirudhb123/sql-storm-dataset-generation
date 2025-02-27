WITH RECURSIVE OrderHierarchy AS (
    SELECT o1.o_orderkey, o1.o_custkey, o1.o_orderdate, o1.o_totalprice, 1 AS level
    FROM orders o1
    WHERE o1.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o2.o_orderkey, o2.o_custkey, o2.o_orderdate, o2.o_totalprice, oh.level + 1
    FROM orders o2
    INNER JOIN OrderHierarchy oh ON o2.o_custkey = oh.o_custkey 
    WHERE o2.o_orderdate > oh.o_orderdate
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
MaxCostSuppliers AS (
    SELECT rs.s_suppkey, rs.s_name
    FROM RankedSuppliers rs
    WHERE rs.cost_rank = 1
)
SELECT DISTINCT
    oh.o_orderkey,
    (SELECT COUNT(DISTINCT l.l_suppkey) 
     FROM lineitem l 
     WHERE l.l_orderkey = oh.o_orderkey 
       AND l.l_discount > COALESCE(NULLIF(NULL, 0), 0)) AS supplying_supp_count,
    CASE 
        WHEN oh.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) THEN 'Above Average'
        ELSE 'Below Average'
    END AS price_comparison,
    rs.s_name AS top_supplier
FROM OrderHierarchy oh
LEFT JOIN MaxCostSuppliers rs ON rs.s_suppkey = 
     (SELECT l.l_suppkey 
      FROM lineitem l 
      WHERE l.l_orderkey = oh.o_orderkey 
      ORDER BY l.l_extendedprice DESC LIMIT 1)
WHERE oh.level > 1
AND EXISTS (
    SELECT 1
    FROM customer c
    WHERE c.c_custkey = oh.o_custkey
      AND c.c_acctbal IS NOT NULL
      AND c.c_mktsegment IN (SELECT r.r_name FROM region r WHERE r.r_regionkey IS NOT NULL)
)
ORDER BY oh.o_orderkey DESC;
