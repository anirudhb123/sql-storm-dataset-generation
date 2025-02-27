WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey <> rh.r_regionkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE l.l_shipdate < CURRENT_DATE - INTERVAL '6 months'
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_revenue DESC
    LIMIT 10
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    SUM(co.o_totalprice) AS total_revenue,
    avg(p.avg_supplycost) AS average_supply_cost,
    COUNT(DISTINCT ts.s_suppkey) AS top_supplier_count
FROM RegionHierarchy r
LEFT JOIN CustomerOrders co ON r.r_regionkey IN (1, 2, 3)  -- Sample filter for certain regions
LEFT JOIN PartSupplierInfo p ON p.total_availqty > 1000
LEFT JOIN TopSuppliers ts ON ts.total_revenue > 10000
WHERE co.o_orderdate >= DATE '2022-01-01' AND co.o_orderdate < CURRENT_DATE
GROUP BY r.r_name
HAVING AVG(p.avg_supplycost) > 20.00 OR COUNT(ts.s_suppkey) IS NOT NULL
ORDER BY total_revenue DESC;
