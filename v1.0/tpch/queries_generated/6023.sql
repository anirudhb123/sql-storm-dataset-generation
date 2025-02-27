WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(*) AS top_supplier_count
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 3
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region_name,
    ts.top_supplier_count,
    AVG(rs.total_supply_cost) AS avg_supply_cost
FROM 
    TopSuppliers ts
JOIN 
    region r ON ts.r_regionkey = r.r_regionkey
JOIN 
    RankedSuppliers rs ON rs.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
GROUP BY 
    r.r_name, ts.top_supplier_count
ORDER BY 
    r.r_name;
