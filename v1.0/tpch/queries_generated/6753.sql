WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
NationRegionStats AS (
    SELECT 
        r.r_name AS region,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(o.total_order_value) AS total_sales_value
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN OrderStats o ON n.n_nationkey = o.c_custkey
    GROUP BY r.r_name
)
SELECT 
    s.s_name AS supplier_name,
    ss.total_available_quantity,
    ss.total_supply_value,
    n.region,
    ns.nation_count,
    os.order_count,
    os.total_order_value,
    os.avg_order_value
FROM SupplierStats ss
JOIN supplier s ON ss.s_suppkey = s.s_suppkey
JOIN NationRegionStats ns ON ns.region = (SELECT r_name FROM region WHERE r_regionkey = (SELECT n_regionkey FROM nation WHERE n_nationkey = s.s_nationkey))
JOIN OrderStats os ON os.c_custkey = s.s_nationkey
WHERE ss.total_supply_value > 10000
ORDER BY ss.total_available_quantity DESC, os.total_order_value DESC
LIMIT 10;
