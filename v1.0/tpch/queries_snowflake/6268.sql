
WITH RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '12 MONTH'
),
PopularParts AS (
    SELECT ps.ps_partkey, SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_partkey
    HAVING SUM(l.l_quantity) > 1000
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    SUM(ro.o_totalprice) AS total_revenue,
    p.p_name AS popular_part_name,
    sd.s_name AS supplier_name,
    sd.parts_supplied
FROM RecentOrders ro
JOIN nation n ON ro.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN PopularParts pp ON pp.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_partkey = ro.o_orderkey)
JOIN SupplierDetails sd ON sd.parts_supplied > 5
JOIN part p ON pp.ps_partkey = p.p_partkey
GROUP BY r.r_name, p.p_name, sd.s_name, sd.parts_supplied;
