WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
),
TotalOrderValue AS (
    SELECT 
        o.o_custkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_custkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(tov.total_value, 0) AS total_value
    FROM 
        customer c
    LEFT JOIN 
        TotalOrderValue tov ON c.c_custkey = tov.o_custkey
),
QualifiedSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank_acctbal <= 5
),
SupplierProductCount AS (
    SELECT 
        ps.ps_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS product_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.total_value,
    qs.nation_name,
    COALESCE(spc.product_count, 0) AS supplier_product_count
FROM 
    CustomerOrders co
LEFT JOIN 
    QualifiedSuppliers qs ON co.total_value > 1000
LEFT JOIN 
    SupplierProductCount spc ON qs.s_suppkey = spc.ps_suppkey
WHERE 
    (co.total_value IS NOT NULL AND co.total_value > 0) OR co.c_name IS NULL
ORDER BY 
    co.total_value DESC, 
    co.c_name;
