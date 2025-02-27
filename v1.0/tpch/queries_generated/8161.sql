WITH supplier_stats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS supplier_nation, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), order_stats AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        COUNT(l.l_orderkey) AS total_lineitems, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), region_summary AS (
    SELECT 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count, 
        SUM(ss.total_supply_value) AS total_supplied_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier_stats ss ON n.n_nationkey = ss.supplier_nation
    GROUP BY 
        r.r_name
)
SELECT 
    ro.r_name AS region_name,
    ro.nation_count, 
    ro.total_supplied_value, 
    os.o_orderstatus, 
    COUNT(os.o_orderkey) AS total_orders,
    SUM(os.order_value) AS total_order_value
FROM 
    region_summary ro
LEFT JOIN 
    order_stats os ON ro.r_name = (SELECT n.r_name FROM nation n JOIN region r ON n.n_regionkey = r.r_regionkey WHERE n.n_nationkey IN (SELECT DISTINCT s.s_nationkey FROM supplier s))
GROUP BY 
    ro.r_name, ro.nation_count, ro.total_supplied_value, os.o_orderstatus
ORDER BY 
    ro.total_supplied_value DESC, total_order_value DESC;
