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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10 AND
        p.p_retailprice > 100.00
),
AggregatedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
    GROUP BY 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_mfgr,
    r.p_brand,
    a.part_count,
    a.total_supply_cost,
    co.c_custkey,
    co.c_name,
    co.total_order_value
FROM 
    RankedParts r
JOIN 
    AggregatedSuppliers a ON r.p_brand = a.s_nationkey
JOIN 
    CustomerOrders co ON r.p_partkey = co.o_orderkey
WHERE 
    rnk <= 5 
ORDER BY 
    r.p_brand, 
    co.total_order_value DESC;
