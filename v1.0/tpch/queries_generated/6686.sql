WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS regional_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(CASE WHEN rs.regional_rank <= 5 THEN rs.total_supply_cost ELSE 0 END) AS top_suppliers_cost
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.n_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    tr.r_name,
    tr.top_suppliers_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    TopRegions tr
JOIN 
    orders o ON tr.r_regionkey = o.o_orderkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    tr.r_name, tr.top_suppliers_cost
ORDER BY 
    tr.top_suppliers_cost DESC, revenue DESC;
