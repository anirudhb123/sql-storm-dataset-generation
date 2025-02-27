WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
),
SupplierDetails AS (
    SELECT 
        ts.region_name,
        ts.nation_name,
        ts.supplier_name,
        CONCAT(ts.supplier_name, ' - Top Supplier') AS detailed_name,
        ts.total_cost
    FROM 
        TopSuppliers ts
)
SELECT 
    sd.region_name,
    sd.nation_name,
    sd.detailed_name,
    SUM(o.o_totalprice) AS total_orders,
    AVG(l.l_discount) AS average_discount,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    SupplierDetails sd
LEFT JOIN 
    supplier s ON sd.supplier_name = s.s_name
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    sd.region_name, sd.nation_name, sd.detailed_name
ORDER BY 
    sd.region_name, total_orders DESC;
