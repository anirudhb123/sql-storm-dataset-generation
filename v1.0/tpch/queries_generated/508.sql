WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_by_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(SUM(os.total_order_value), 0) AS total_value,
    AVG(COALESCE(ss.total_supply_cost, 0)) AS avg_supply_cost,
    COUNT(DISTINCT ss.s_suppkey) AS total_suppliers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
LEFT JOIN SupplierStats ss ON ss.total_parts > 0
GROUP BY r.r_name, n.n_name
ORDER BY total_value DESC NULLS LAST, avg_supply_cost DESC;
