WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 5000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationPartSupply AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT ps.ps_partkey) AS part_count, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM nation n
    LEFT JOIN partsupp ps ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey)
    GROUP BY n.n_nationkey, n.n_name
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
           AVG(l.l_tax) AS avg_tax, 
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    ch.c_name AS customer_name, 
    co.order_count, 
    co.total_spent, 
    n.n_name AS nation_name, 
    n.part_count,
    n.total_supply_cost,
    SUM(COALESCE(li.net_sales, 0)) AS total_net_sales,
    AVG(COALESCE(li.avg_tax, 0)) AS avg_tax_collected
FROM CustomerOrders co
JOIN customer ch ON co.c_custkey = ch.c_custkey
LEFT JOIN NationPartSupply n ON ch.c_nationkey = n.n_nationkey
LEFT JOIN LineItemAnalysis li ON co.order_count > 0
GROUP BY ch.c_name, co.order_count, co.total_spent, n.n_name, n.part_count
HAVING SUM(COALESCE(li.net_sales, 0)) > 1000
ORDER BY total_spent DESC, customer_name ASC;
