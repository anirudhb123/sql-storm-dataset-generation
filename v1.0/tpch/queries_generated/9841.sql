WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS brand_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        rp.total_supply_cost
    FROM 
        RankedParts rp
    WHERE 
        rp.brand_rank <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
)
SELECT 
    tp.p_name,
    tp.p_brand,
    tp.total_supply_cost,
    sd.s_name,
    sd.s_acctbal,
    cod.c_name,
    cod.o_orderdate,
    cod.o_totalprice
FROM 
    TopParts tp 
JOIN 
    SupplierDetails sd ON tp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_acctbal > 10000))
JOIN 
    CustomerOrderDetails cod ON tp.p_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_totalprice > cod.o_totalprice)
ORDER BY 
    tp.total_supply_cost DESC, 
    sd.s_acctbal DESC, 
    cod.o_orderdate DESC;
