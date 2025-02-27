WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, c.c_acctbal
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name
    FROM CustomerOrders o
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM CustomerOrders)
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(sp.total_supply_cost) AS average_supply_cost,
    SUM(hv.o_totalprice) AS total_high_value_sales
FROM RankedSuppliers s
JOIN supplier s2 ON s.s_suppkey = s2.s_suppkey
JOIN nation n ON s2.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN SupplierParts sp ON s.s_partkey = sp.ps_partkey
LEFT JOIN HighValueOrders hv ON hv.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = sp.ps_partkey)
GROUP BY r.r_name
HAVING AVG(sp.total_supply_cost) > 1000
ORDER BY total_high_value_sales DESC;
