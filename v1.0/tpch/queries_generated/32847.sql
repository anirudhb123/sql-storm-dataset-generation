WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey, o.o_totalprice, 1 as level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
), CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), LineItemStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, COUNT(*) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
), PartSupplierSummary AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, ps.ps_supplycost
)
SELECT 
    c.c_name,
    cs.total_spent,
    l.revenue,
    l.item_count,
    p.p_name,
    p.ps_supplycost,
    ps.total_available,
    (SELECT MAX(p_retailprice) FROM part) AS max_retailprice,
    RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
FROM CustomerSummary cs
JOIN customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN LineItemStats l ON l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
LEFT JOIN PartSupplierSummary p ON p.p_partkey IN (
    SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_custkey = c.c_custkey
)
WHERE cs.total_spent > 1000 AND p.ps_supplycost IS NOT NULL
ORDER BY cs.total_spent DESC, l.revenue DESC
LIMIT 10;
