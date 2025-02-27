WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate > (SELECT MAX(o_orderdate) FROM orders WHERE o_orderstatus = 'F')
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) AS total_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
    HAVING total_availqty > 100
),
CustomerBalance AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_amount,
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT n.n_name,
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       AVG(cb.total_spent) AS avg_spent,
       SUM(od.net_amount) AS total_net_amount,
       MAX(od.unique_parts) AS max_unique_parts,
       RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(od.net_amount) DESC) AS region_rank
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerBalance cb ON c.c_custkey = cb.c_custkey
LEFT JOIN OrderDetails od ON cb.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'O')
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY region_rank, total_net_amount DESC;
