WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           o.o_orderstatus, 
           0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           o.o_orderstatus, 
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 3
),
SupplierCost AS (
    SELECT ps.ps_partkey, 
           s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_nationkey
),
CustomerDetails AS (
    SELECT c.c_custkey,
           c.c_name,
           c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rn
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
LineItemStats AS (
    SELECT l.l_orderkey, 
           l.l_partkey, 
           AVG(l.l_discount) AS avg_discount,
           COUNT(l.l_linenumber) AS total_items
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey
)
SELECT DISTINCT 
    oh.o_orderkey,
    oh.o_orderdate,
    c.c_name,
    COALESCE(s.total_cost, 0) AS supplier_cost,
    lis.avg_discount,
    lis.total_items,
    CASE WHEN oh.o_totalprice > 1000 THEN 'High Value' ELSE 'Standard' END AS order_value_category
FROM OrderHierarchy oh
LEFT JOIN CustomerDetails c ON c.c_custkey = oh.o_orderkey
LEFT JOIN SupplierCost s ON s.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = oh.o_orderkey)
LEFT JOIN LineItemStats lis ON lis.l_orderkey = oh.o_orderkey
WHERE oh.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
ORDER BY oh.o_orderdate DESC, s.total_cost DESC, c.c_name;
