WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rn
    FROM 
        part p
),
TopSupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        c.c_mktsegment,
        o.o_orderdate,
        (SELECT COUNT(DISTINCT l.l_orderkey) 
         FROM lineitem l 
         WHERE l.l_orderkey = o.o_orderkey) AS num_items
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_orderdate >= DATE '2023-01-01'
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    tsp.s_name AS supplier_name,
    tsp.ps_supplycost,
    fo.c_name AS customer_name,
    fo.o_totalprice,
    fo.num_items
FROM 
    RankedParts rp
JOIN 
    TopSupplierParts tsp ON rp.p_partkey = tsp.ps_partkey
JOIN 
    FilteredOrders fo ON fo.o_totalprice > 1000
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_brand, fo.o_totalprice DESC;
