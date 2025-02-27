WITH SupplierOrderCount AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS open_orders,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS fulfilled_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    sc.s_name AS supplier,
    pc.p_name AS part_name,
    sp.avg_supply_cost,
    sp.total_quantity_sold,
    soc.open_orders,
    soc.fulfilled_orders
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
JOIN 
    supplier sc ON ns.n_nationkey = sc.s_nationkey
JOIN 
    partsupp ps ON sc.s_suppkey = ps.ps_suppkey
JOIN 
    PartStatistics sp ON ps.ps_partkey = sp.p_partkey
JOIN 
    SupplierOrderCount soc ON sc.s_suppkey = soc.s_suppkey
WHERE 
    sp.avg_supply_cost > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    r.r_name, ns.n_name, sc.s_name, sp.total_quantity_sold DESC;
