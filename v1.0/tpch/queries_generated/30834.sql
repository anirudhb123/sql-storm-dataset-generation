WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, o_comment,
           1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice, o.comment,
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
CustomerRevenue AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedNations AS (
    SELECT n.n_nationkey, n.n_name, 
           ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS nation_rank
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    oh.o_orderkey,
    cr.c_name,
    cr.total_revenue,
    ps.p_name,
    ps.total_cost,
    rn.n_name,
    rn.nation_rank
FROM OrderHierarchy oh
JOIN CustomerRevenue cr ON oh.o_custkey = cr.c_custkey
JOIN lineitem li ON oh.o_orderkey = li.l_orderkey
JOIN part p ON li.l_partkey = p.p_partkey
JOIN PartSuppliers ps ON p.p_partkey = ps.p_partkey
JOIN RankedNations rn ON cr.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = rn.n_nationkey)
WHERE ps.rn = 1 AND cr.total_revenue IS NOT NULL
ORDER BY cr.total_revenue DESC, ps.total_cost ASC;
