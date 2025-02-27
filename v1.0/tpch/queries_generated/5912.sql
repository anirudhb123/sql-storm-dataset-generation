WITH SupplierPartCost AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, ps.ps_partkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT c.c_custkey, o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
)
SELECT nr.r_regionkey, nr.n_name AS nation_name, spc.s_name AS supplier_name, COUNT(DISTINCT co.o_orderkey) AS total_orders,
       SUM(spc.total_supply_cost) AS total_supply_cost, AVG(co.o_totalprice) AS avg_order_value
FROM NationRegion nr
JOIN CustomerOrders co ON nr.n_nationkey = co.o_orderkey % 4  -- Example of some join condition for diversity
JOIN SupplierPartCost spc ON nr.n_nationkey = spc.s_suppkey % 4  -- Example of some join condition for diversity
WHERE co.o_orderstatus = 'O'
GROUP BY nr.r_regionkey, nr.n_name, spc.s_name
ORDER BY total_orders DESC, total_supply_cost DESC;
