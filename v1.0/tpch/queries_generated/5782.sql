WITH NationSupplier AS (
    SELECT n.n_name, s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, s.s_suppkey
), PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
), HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
), RegionSummary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT ns.n_name, pd.p_name, pd.avg_supply_cost, hvo.total_order_value, rs.r_name, rs.nation_count
FROM NationSupplier ns
JOIN PartDetails pd ON ns.s_suppkey = pd.p_partkey
JOIN HighValueOrders hvo ON hvo.total_order_value > ns.total_supply_cost
JOIN RegionSummary rs ON ns.n_name IN (SELECT n.n_name FROM nation n WHERE n.n_nationkey IN 
                                          (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ns.s_suppkey))
ORDER BY hvo.total_order_value DESC, pd.avg_supply_cost ASC;
