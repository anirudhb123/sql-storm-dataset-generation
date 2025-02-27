WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_extended_price,
        AVG(l.l_discount) AS avg_discount,
        COUNT(*) AS total_line_items
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    ss.s_name,
    ss.nation_name,
    ss.total_available_qty,
    ss.total_supply_cost,
    os.total_orders,
    os.total_spent,
    os.avg_order_value,
    ls.total_quantity,
    ls.total_extended_price,
    ls.avg_discount,
    ls.total_line_items
FROM supplier_summary ss
JOIN order_summary os ON ss.total_parts > 5
JOIN lineitem_summary ls ON ss.s_suppkey IN (
    SELECT DISTINCT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
)
ORDER BY ss.total_supply_cost DESC, os.avg_order_value DESC
LIMIT 50;
