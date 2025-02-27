WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
), 
NationSales AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON c.c_nationkey = s.s_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
), 
PartSupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    p.p_name,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    ns.total_sales,
    psc.total_cost,
    (p.p_retailprice - COALESCE(psc.total_cost, 0)) AS profit_per_part,
    CASE 
       WHEN profit_per_part > 0 THEN 'Profitable' 
       ELSE 'Not Profitable' 
    END AS profit_status
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.s_suppkey
LEFT JOIN 
    NationSales ns ON rs.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
LEFT JOIN 
    PartSupplierCosts psc ON p.p_partkey = psc.ps_partkey
WHERE 
    p.p_size > 10 AND 
    (rs.rn IS NULL OR rs.rn <= 3) 
ORDER BY 
    profit_per_part DESC NULLS LAST;
