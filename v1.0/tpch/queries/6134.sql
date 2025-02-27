WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueNations AS (
    SELECT 
        n.n_nationkey,
        SUM(cs.total_spent) AS nation_total_spent
    FROM nation n
    JOIN customerStats cs ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
    GROUP BY n.n_nationkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    hv.nation_total_spent,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.total_revenue) AS total_revenue
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN HighValueNations hv ON hv.n_nationkey = n.n_nationkey
JOIN RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN customer c ON o.o_custkey = c.c_custkey WHERE c.c_nationkey = n.n_nationkey)
GROUP BY r.r_name, n.n_name, hv.nation_total_spent
ORDER BY total_revenue DESC;
