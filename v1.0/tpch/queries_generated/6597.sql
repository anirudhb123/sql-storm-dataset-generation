WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ps.s_suppkey,
    ps.s_name,
    ns.n_name AS supplier_nation,
    ss.total_supply_cost,
    ss.total_parts_supplied,
    os.o_orderdate,
    os.total_order_value
FROM SupplierStats ss
JOIN supplier ps ON ss.s_suppkey = ps.s_suppkey
JOIN OrderStats os ON os.total_order_value > 1000
JOIN NationStats ns ON ps.s_nationkey = ns.n_nationkey
ORDER BY total_order_value DESC, total_supply_cost DESC
LIMIT 100;
