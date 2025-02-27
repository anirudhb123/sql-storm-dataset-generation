WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_region
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
), TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(rs.s_suppkey) AS top_supplier_count
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON rs.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
    WHERE 
        rs.rank_within_region <= 3
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_sales,
    AVG(o.o_totalprice) AS average_order_value,
    ts.top_supplier_count
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TopSuppliers ts ON r.r_regionkey = ts.r_regionkey
WHERE 
    o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate <= DATE '2022-12-31'
GROUP BY 
    n.n_name, r.r_name, ts.top_supplier_count
ORDER BY 
    total_sales DESC, region_name ASC;
