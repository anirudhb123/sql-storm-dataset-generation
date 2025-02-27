WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_cost,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(ST.total_cost, 0) AS total_supply_cost,
    COALESCE(OS.total_line_cost, 0) AS highest_order_total,
    (SELECT AVG(total_cost) FROM SupplierStats) AS average_supplier_cost
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN SupplierStats ST ON ST.s_suppkey = (
    SELECT s.s_suppkey
    FROM supplier s
    WHERE s.s_nationkey = n.n_nationkey
    ORDER BY ST.total_cost DESC
    LIMIT 1
)
LEFT JOIN OrderSummary OS ON OS.o_orderkey = (
    SELECT o.o_orderkey
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC
    LIMIT 1
)
WHERE n.r_regionkey = 1
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY n.n_name;
