WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopNations AS (
    SELECT 
        n.n_name,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS nation_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 5
)
SELECT 
    r.r_name,
    COALESCE(SUM(CASE WHEN ro.revenue_rank <= 3 THEN ro.total_revenue ELSE NULL END), 0) AS top_order_revenue,
    COUNT(DISTINCT sr.s_suppkey) AS unique_suppliers,
    MAX(CASE WHEN t.nation_rank <= 5 THEN t.n_name ELSE 'Other' END) AS top_nation
FROM region r
LEFT JOIN RankedOrders ro ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey IN (SELECT DISTINCT s.s_nationkey FROM supplier s))
LEFT JOIN SupplierRevenue sr ON sr.total_supply_cost > 1000
LEFT JOIN TopNations t ON 1 = 1
WHERE r.r_name IS NOT NULL OR r.r_name = 'UNKNOWN'
GROUP BY r.r_name
HAVING SUM(COALESCE(ro.total_revenue, 0)) > 50000
ORDER BY top_order_revenue DESC, unique_suppliers ASC;
