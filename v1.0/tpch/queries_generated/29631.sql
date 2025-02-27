WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > 20.00
),
NationSupplier AS (
    SELECT 
        n.n_name,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        c.c_address,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        c.c_name, c.c_address
),
FinalBenchmark AS (
    SELECT 
        rp.p_name,
        rp.p_size,
        ns.n_name,
        ns.total_parts,
        co.c_name,
        co.total_orders,
        co.total_spent
    FROM 
        RankedParts rp
    JOIN 
        NationSupplier ns ON rp.p_brand = SUBSTRING(ns.s_name, 1, LENGTH(rp.p_brand))
    JOIN 
        CustomerOrders co ON ns.total_parts > 5 AND co.total_orders > 10
)
SELECT 
    p_name, 
    p_size, 
    n_name, 
    total_parts, 
    c_name, 
    total_orders, 
    total_spent
FROM 
    FinalBenchmark
ORDER BY 
    total_spent DESC, 
    total_orders DESC;
