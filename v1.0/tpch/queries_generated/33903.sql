WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS level
    FROM nation n
    WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'AMERICA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_regionkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderLineSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CombinedData AS (
    SELECT 
        nh.n_name,
        ss.s_name,
        ol.o_orderdate,
        ol.net_revenue,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost
    FROM NationHierarchy nh
    LEFT JOIN SupplierStats ss ON nh.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_nationkey = nh.n_nationkey)
    LEFT JOIN OrderLineSummary ol ON ol.o_orderdate >= '2023-01-01' AND ol.o_orderdate <= '2023-12-31'
)
SELECT 
    n.n_name AS nation_name,
    AVG(CASE WHEN cd.total_supply_cost IS NOT NULL THEN cd.total_supply_cost ELSE NULL END) AS avg_supply_cost,
    SUM(cd.net_revenue) AS total_net_revenue,
    COUNT(DISTINCT cd.o_orderdate) AS unique_order_dates
FROM CombinedData cd
JOIN nation n ON cd.n_name = n.n_name
GROUP BY n.n_name
ORDER BY total_net_revenue DESC, avg_supply_cost DESC
LIMIT 10;
