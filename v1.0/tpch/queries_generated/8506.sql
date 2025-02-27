WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, ps.ps_partkey
),
FilteredSuppliers AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        rs.s_name,
        rs.total_avail_qty,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN
        part p ON p.p_partkey = rs.ps_partkey
    JOIN
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank = 1
)
SELECT 
    region,
    nation,
    COUNT(*) AS num_suppliers,
    SUM(total_avail_qty) AS total_avail_qty,
    AVG(total_cost) AS avg_cost_per_supplier
FROM 
    FilteredSuppliers
GROUP BY 
    region, nation
ORDER BY 
    region, nation;
