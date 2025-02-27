WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
SalesData AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM lineitem li
    GROUP BY li.l_orderkey
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost) > 10000
),
RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY co.total_orders DESC) AS order_rank
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
)
SELECT 
    n.n_name AS nation_name,
    p.p_name AS part_name,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ld.revenue) DESC) AS revenue_rank,
    COALESCE(SUM(ld.revenue), 0) AS total_revenue,
    (SELECT COUNT(*) FROM SupplierHierarchy sh WHERE sh.s_nationkey = n.n_nationkey) AS supplier_count
FROM nation n
JOIN lineitem li ON li.l_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps
    JOIN TopSuppliers ts ON ps.ps_suppkey = ts.ps_suppkey
)
LEFT JOIN SalesData ld ON li.l_orderkey = ld.l_orderkey
JOIN part p ON li.l_partkey = p.p_partkey
LEFT JOIN RankedCustomers rc ON rc.c_custkey = li.l_suppkey
GROUP BY n.n_nationkey, p.p_name
ORDER BY total_revenue DESC;
