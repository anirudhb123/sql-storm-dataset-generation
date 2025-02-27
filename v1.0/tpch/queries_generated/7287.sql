WITH PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, s.s_name, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
RegionNation AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    rn.r_name AS region_name,
    pn.p_name AS part_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(CASE WHEN co.o_orderdate < CURRENT_DATE - INTERVAL '1 year' THEN 1 ELSE 0 END) AS orders_last_year
FROM PartSupplier ps
JOIN RegionNation rn ON ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE n.n_nationkey = rn.n_nationkey)
JOIN CustomerOrders co ON ps.ps_partkey IN (SELECT li.l_partkey FROM lineitem li JOIN orders o ON li.l_orderkey = o.o_orderkey WHERE o.o_orderkey = co.o_orderkey)
GROUP BY rn.r_name, pn.p_name
ORDER BY total_orders DESC, average_supply_cost ASC;
