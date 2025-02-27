WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
), 

CustomerOrders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 

PartSupplierStats AS (
    SELECT p.p_partkey, COUNT(ps.ps_suppkey) AS supplier_count, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sh.s_name AS supplier_name,
    co.order_count,
    co.total_spent,
    p.p_name,
    ps.supplier_count,
    ps.avg_supply_cost,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    COALESCE(AVG(pl.l_extendedprice), 0) AS avg_line_item_price
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN CustomerOrders co ON sh.s_suppkey = co.c_custkey
JOIN part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sh.s_suppkey)
JOIN PartSupplierStats ps ON p.p_partkey = ps.p_partkey
LEFT JOIN lineitem pl ON pl.l_partkey = p.p_partkey AND pl.l_returnflag = 'R'
GROUP BY r.r_name, n.n_name, sh.s_name, co.order_count, co.total_spent, p.p_name, ps.supplier_count, ps.avg_supply_cost
HAVING order_count > 0 OR supplier_count > 0
ORDER BY r.r_name, n.n_name, supplier_name, total_spent DESC;
