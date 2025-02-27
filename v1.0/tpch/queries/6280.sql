WITH NationAgg AS (
    SELECT n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerOrder AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, COALESCE(SUM(os.revenue), 0) AS total_revenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT na.n_name, SUM(co.total_revenue) AS total_revenue_by_nation
FROM NationAgg na
JOIN supplier s ON na.n_name IN (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey)
JOIN CustomerOrder co ON s.s_nationkey = co.c_custkey
GROUP BY na.n_name
ORDER BY total_revenue_by_nation DESC
LIMIT 10;