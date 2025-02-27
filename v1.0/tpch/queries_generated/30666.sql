WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    UNION ALL
    SELECT o2.o_orderkey, o2.o_custkey, o2.o_orderdate, o2.o_totalprice, oh.order_level + 1
    FROM orders o2
    JOIN OrderHierarchy oh ON o2.o_custkey = oh.o_custkey
    WHERE o2.o_orderdate > oh.o_orderdate AND o2.o_orderstatus = 'F'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spending,
           CASE WHEN SUM(o.o_totalprice) IS NULL THEN 0 ELSE SUM(o.o_totalprice) END AS total_spending_nonnull
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT n.n_name, 
       COUNT(DISTINCT cd.c_custkey) AS unique_customers, 
       AVG(cd.total_spending) AS avg_spending,
       MAX(sd.total_supply_cost) AS max_supply_cost,
       SUM(COALESCE(cd.order_count, 0)) AS total_orders,
       COUNT(oh.o_orderkey) AS hierarchy_order_count
FROM nation n
LEFT JOIN CustomerDetails cd ON n.n_nationkey = cd.c_nationkey
LEFT JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
LEFT JOIN OrderHierarchy oh ON cd.c_custkey = oh.o_custkey
GROUP BY n.n_name
HAVING AVG(cd.total_spending) > (SELECT AVG(total_spending) FROM CustomerDetails)
ORDER BY unique_customers DESC;
