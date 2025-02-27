WITH SupplierCost AS (
    SELECT ps_partkey, ps_suppkey, 
           SUM(ps_supplycost) AS total_supply_cost,
           COUNT(*) AS supply_count
    FROM partsupp
    GROUP BY ps_partkey, ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
),
LineItemSummary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate <= CURRENT_DATE
    GROUP BY l.l_orderkey
),
RevenueBySupplier AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.total_revenue) AS supplier_revenue
    FROM SupplierCost sc 
    JOIN lineitem l ON sc.ps_partkey = l.l_partkey
    JOIN supplier s ON sc.ps_suppkey = s.s_suppkey
    JOIN CustomerOrders co ON l.l_orderkey = co.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT r.r_name AS region_name, 
       n.n_name AS nation_name,
       s.s_name AS supplier_name,
       COALESCE(SUM(rbs.supplier_revenue), 0) AS total_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RevenueBySupplier rbs ON s.s_suppkey = rbs.s_suppkey
WHERE r.r_name LIKE 'N%' 
AND n.n_comment NOT LIKE '%test%'
GROUP BY r.r_name, n.n_name, s.s_name
ORDER BY region_name, nation_name, total_revenue DESC
LIMIT 10;
