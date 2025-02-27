WITH RECURSIVE customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IS NOT NULL
    UNION ALL
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM customer_orders co
    JOIN orders o ON co.o_orderkey = o.o_orderkey
    WHERE o.o_orderdate < CURRENT_DATE
),
supplier_summary AS (
    SELECT ps.ps_partkey, s.s_suppkey, SUM(ps.ps_availqty) AS total_availqty, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY ps.ps_partkey, s.s_suppkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey
),
ranked_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, 
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT DISTINCT 
    c.c_name AS customer_name,
    n.n_name AS nation_name,
    SUM(o.total_revenue) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(s.total_availqty, 0) AS total_available_quantity,
    COALESCE(s.total_supplycost, 0) AS total_supply_cost
FROM customer c
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN lineitem_summary o ON o.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
LEFT JOIN supplier_summary s ON s.ps_partkey IN (SELECT l_partkey FROM lineitem WHERE l_orderkey = o.l_orderkey)
LEFT JOIN ranked_orders r ON r.o_orderkey = o.l_orderkey AND r.rank = 1
WHERE c.c_acctbal IS NOT NULL AND n.n_regionkey IS NOT NULL
GROUP BY c.c_name, n.n_name
HAVING SUM(o.total_revenue) > 10000
ORDER BY total_revenue DESC;
