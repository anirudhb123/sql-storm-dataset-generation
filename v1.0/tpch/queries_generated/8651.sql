WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
),
NationRegions AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT ns.n_name AS nation_name, 
       nr.r_name AS region_name, 
       ss.s_name AS supplier_name, 
       cs.c_name AS customer_name,
       SUM(cs.total_order_value) AS total_value,
       SUM(ss.total_supplycost) AS total_cost
FROM CustomerOrders cs
JOIN SupplierSummary ss ON ss.s_nationkey = cs.c_nationkey
JOIN NationRegions nr ON cs.c_nationkey = nr.n_nationkey
JOIN NationRegions ns ON ns.r_regionkey = nr.r_regionkey
WHERE cs.total_order_value > 0
GROUP BY ns.n_name, nr.r_name, ss.s_name, cs.c_name
ORDER BY total_value DESC, total_cost DESC
LIMIT 10;
