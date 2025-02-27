WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ns.n_name AS supplier_nation,
    rs.region_name,
    COUNT(DISTINCT ss.s_suppkey) AS total_suppliers,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    SUM(ss.total_avail_qty) AS total_available_quantity,
    AVG(ss.avg_supply_cost) AS average_supply_cost,
    SUM(os.total_revenue) AS total_revenue,
    CASE 
        WHEN SUM(os.total_revenue) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Data Available'
    END AS revenue_status
FROM 
    NationRegion ns
LEFT JOIN 
    SupplierStats ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN 
    OrderStats os ON ss.s_nationkey = (SELECT n.c_nationkey FROM customer c WHERE c.c_custkey = os.o_custkey)
GROUP BY 
    ns.n_name, rs.region_name
ORDER BY 
    total_revenue DESC NULLS LAST;
