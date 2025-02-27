WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
),
HighValueNations AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        n.n_name
    HAVING 
        SUM(o.o_totalprice) > 1000000
)
SELECT 
    rs.region_name,
    rs.nation_name,
    rs.s_name,
    rs.total_supply_cost,
    hvn.customer_count,
    hvn.total_revenue
FROM 
    RankedSuppliers rs
JOIN 
    HighValueNations hvn ON rs.nation_name = hvn.n_name
WHERE 
    rs.supplier_rank <= 3
ORDER BY 
    rs.region_name, rs.total_supply_cost DESC;
