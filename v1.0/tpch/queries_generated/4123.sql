WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),    
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_container
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_brand = 'Brand#42'
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    cn.n_name AS nation_name,
    hp.o_orderkey,
    COALESCE(rn.s_name, 'No Supplier') AS supplier_name,
    hp.total_value,
    sp.p_name,
    sp.p_container,
    cn.c_acctbal
FROM 
    HighValueOrders hp
LEFT JOIN 
    RankedSuppliers rn ON rn.rn = 1 
LEFT JOIN 
    SupplierParts sp ON sp.ps_suppkey = rn.s_suppkey
JOIN 
    CustomerNation cn ON cn.c_custkey = (SELECT o_custkey FROM orders WHERE o_orderkey = hp.o_orderkey)
WHERE 
    hp.total_value IS NOT NULL 
    AND (cn.c_acctbal IS NULL OR cn.c_acctbal > 500) 
ORDER BY 
    cn.n_name, hp.total_value DESC;
