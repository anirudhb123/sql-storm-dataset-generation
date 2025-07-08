
WITH RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_nationkey, c.c_acctbal, o.o_totalprice
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, RANK() OVER (ORDER BY pp.total_supply_cost DESC) AS supply_rank
    FROM part p
    JOIN PartSuppliers pp ON p.p_partkey = pp.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    SUM(ro.o_totalprice) AS total_sales,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    LISTAGG(CONCAT(rp.p_name, ' (Rank: ', rp.supply_rank, ')'), ', ') AS top_parts
FROM RecentOrders ro
LEFT JOIN nation n ON ro.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN RankedParts rp ON EXISTS (
    SELECT 1
    FROM lineitem l
    WHERE l.l_orderkey = ro.o_orderkey AND l.l_partkey = rp.p_partkey
)
GROUP BY r.r_name
HAVING SUM(ro.o_totalprice) > (
    SELECT AVG(o_totalprice) 
    FROM RecentOrders
) OR COUNT(DISTINCT ro.o_orderkey) > 10
ORDER BY total_sales DESC;
