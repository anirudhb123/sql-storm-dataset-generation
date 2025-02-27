WITH regional_supplier AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, r.r_name, s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        c.c_name AS customer_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_name
),
detailed_summary AS (
    SELECT 
        rs.nation_name,
        rs.region_name,
        rs.s_name,
        os.customer_name,
        os.total_orders,
        os.order_count,
        rs.total_available_qty,
        rs.total_supply_cost
    FROM regional_supplier rs
    JOIN order_summary os ON rs.total_available_qty > 100 AND rs.total_supply_cost < 50000
)
SELECT 
    ds.nation_name,
    ds.region_name,
    ds.s_name,
    ds.customer_name,
    ds.total_orders,
    ds.order_count,
    ds.total_available_qty,
    ds.total_supply_cost
FROM detailed_summary ds
ORDER BY ds.region_name, ds.nation_name, ds.customer_name;
