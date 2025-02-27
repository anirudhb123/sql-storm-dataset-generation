WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        ps.ps_supplycost,
        s.s_name AS supplier_name 
    FROM 
        partsupp ps 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    JOIN 
        RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey 
    WHERE 
        s.rnk <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_comment 
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_totalprice > 1000 
        AND o.o_orderdate >= '2023-01-01'
)
SELECT 
    cp.supplier_name,
    cp.p_name,
    cp.p_brand,
    cp.p_type,
    cu.c_name AS customer_name,
    cu.o_orderkey,
    cu.o_totalprice,
    cu.o_orderdate,
    cu.o_orderstatus,
    cp.ps_supplycost
FROM 
    SupplierParts cp
JOIN 
    CustomerOrders cu ON cp.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = cu.o_orderkey
    )
ORDER BY 
    cp.supplier_name, 
    cu.o_totalprice DESC;
