WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        r.r_name AS region,
        CONCAT(s.s_name, ' - ', n.n_name) AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartsWithSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        sd.supplier_nation,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
),
TopSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.supplier_nation
    FROM 
        PartsWithSuppliers ps
    WHERE 
        ps.supplier_rank <= 3
)
SELECT 
    p.p_partkey,
    p.p_name,
    STRING_AGG(ps.supplier_nation, ', ') AS top_suppliers_info,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM 
    part p
JOIN 
    TopSuppliers ps ON p.p_partkey = ps.p_partkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    p.p_partkey;
