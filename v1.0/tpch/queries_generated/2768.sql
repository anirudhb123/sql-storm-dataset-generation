WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
FilteredLineItems AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(*) AS item_count
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-07-01'
    GROUP BY l.l_orderkey
), 
SupplierCosts AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
    GROUP BY ps.ps_partkey
)
SELECT DISTINCT
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(lo.revenue) AS total_revenue,
    AVG(lo.item_count) AS avg_items_per_order,
    CASE 
        WHEN SUM(sc.total_supply_cost) IS NULL THEN 'No Cost Data' 
        ELSE TO_CHAR(SUM(sc.total_supply_cost), 'FM$999,999,999.00')
    END AS total_supply_cost
FROM nation n
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN RankedOrders ro ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey))
LEFT JOIN FilteredLineItems lo ON ro.o_orderkey = lo.l_orderkey
LEFT JOIN SupplierCosts sc ON lo.l_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = sc.ps_partkey)
WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
GROUP BY n.n_name
HAVING SUM(lo.revenue) > 10000.00
ORDER BY total_revenue DESC;
