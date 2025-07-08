
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        o.o_custkey
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.region_name,
    cr.nation_name,
    COUNT(DISTINCT cr.c_custkey) AS customers_count,
    COALESCE(SUM(t.total_spent), 0) AS total_spent,
    LISTAGG(s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS top_suppliers
FROM 
    CustomerRegions cr
LEFT JOIN 
    TotalOrders t ON cr.c_custkey = t.o_custkey
LEFT JOIN 
    RankedSuppliers s ON cr.c_custkey = s.s_suppkey AND s.supplier_rank = 1
GROUP BY 
    cr.region_name, cr.nation_name
HAVING 
    COUNT(DISTINCT cr.c_custkey) > 10
ORDER BY 
    total_spent DESC, customers_count DESC;
