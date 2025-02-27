WITH RECURSIVE OrdersHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 
           o_orderstatus, o_comment, 1 AS level
    FROM orders
    WHERE o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_custkey, oh.o_orderdate, oh.o_totalprice, 
           oh.o_orderstatus, oh.o_comment, oh.level + 1
    FROM OrdersHierarchy oh
    JOIN orders o ON oh.o_custkey = o.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
CustomerSummaries AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           ARRAY_AGG(DISTINCT CASE WHEN o.o_orderstatus = 'F' THEN o.o_orderkey END) AS finished_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT ch.level, cs.c_name, cs.total_spent, ps.p_name, ps.total_quantity_sold, 
       COALESCE(r.rank, 0) AS supplier_rank
FROM OrdersHierarchy ch
JOIN CustomerSummaries cs ON ch.o_custkey = cs.c_custkey
JOIN PartSuppliers ps ON ch.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = ch.o_orderkey)
LEFT JOIN RankedSuppliers r ON r.s_suppkey IN (SELECT l.l_suppkey FROM lineitem l WHERE l.l_orderkey = ch.o_orderkey)
WHERE cs.total_spent > 1000 AND ch.level <= 5
ORDER BY cs.total_spent DESC, ch.o_orderdate ASC;
