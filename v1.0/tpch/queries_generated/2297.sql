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
NationRegions AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    ns.n_name AS supplier_nation,
    rr.region_name,
    ss.s_name AS supplier_name,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    od.order_total,
    od.line_item_count
FROM 
    SupplierStats ss
LEFT JOIN 
    NationRegions ns ON ss.s_nationkey = ns.n_nationkey
LEFT JOIN 
    OrderDetails od ON ss.s_suppkey = od.o_custkey
WHERE 
    ss.total_avail_qty > (
        SELECT 
            AVG(total_avail_qty)
        FROM 
            SupplierStats
    )
ORDER BY 
    od.order_total DESC, 
    ns.n_name ASC
LIMIT 100;
