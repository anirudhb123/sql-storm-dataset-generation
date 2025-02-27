WITH RecursiveOrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), 
SupplierPartDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS high_value_order_count,
    AVG(o.o_totalprice) AS average_order_value,
    MAX(sup.total_supply_cost) AS max_supply_cost,
    STRING_AGG(DISTINCT part.p_name, ', ') AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN RecursiveOrderSummary o ON c.c_custkey = o.o_orderkey
LEFT JOIN HighValueOrders hvo ON o.o_orderkey = hvo.o_orderkey
LEFT JOIN SupplierPartDetails sup ON sup.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL
    AND ps.ps_supplycost > 0
)
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY high_value_order_count DESC, average_order_value DESC;
