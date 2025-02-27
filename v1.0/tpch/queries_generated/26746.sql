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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_per_brand
    FROM 
        part p
    WHERE 
        LOWER(p.p_mfgr) LIKE '%ec%' 
        AND p.p_retailprice > (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_partkey = p.p_partkey)
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000 
        AND n.n_name IN (SELECT DISTINCT r_name FROM region WHERE r_comment LIKE '%Europe%')
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        STRING_AGG(DISTINCT p.p_name, ', ') AS parts_ordered
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        RankedParts rp ON l.l_partkey = rp.p_partkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderpriority
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    co.o_orderdate,
    co.o_orderpriority,
    fs.s_name AS supplier_name,
    fs.nation_name,
    co.parts_ordered
FROM 
    CustomerOrders co
JOIN 
    FilteredSuppliers fs ON fs.s_suppkey IN (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM RankedParts p))
WHERE 
    co.o_orderdate > '2022-01-01' 
ORDER BY 
    co.o_totalprice DESC, co.c_name;
