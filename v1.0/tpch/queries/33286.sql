
WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
SupplierRegion AS (
    SELECT s.s_suppkey, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
OrderLineValues AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_rank
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name,
    co.order_count,
    sr.region_name,
    COALESCE(SUM(hl.total_supply_value), 0) AS high_value_supply_total,
    SUM(olv.total_line_value) AS total_order_value,
    COUNT(DISTINCT o.o_orderkey) AS unique_order_count
FROM customer c
JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN SupplierRegion sr ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = sr.nation_name)
LEFT JOIN HighValueSuppliers hl ON sr.s_suppkey = hl.ps_suppkey
JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN OrderLineValues olv ON o.o_orderkey = olv.l_orderkey
GROUP BY c.c_name, co.order_count, sr.region_name
HAVING SUM(olv.total_line_value) > 5000
ORDER BY total_order_value DESC, co.order_count ASC;
