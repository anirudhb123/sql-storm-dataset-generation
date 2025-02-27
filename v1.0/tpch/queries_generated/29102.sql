WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER(PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ps.ps_supplycost,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100.00
    ORDER BY 
        profit_margin DESC
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        RANK() OVER(ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    tp.c_name AS top_customer,
    tp.o_orderkey,
    tp.o_totalprice,
    hs.p_name AS high_value_part,
    hs.profit_margin
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
JOIN 
    RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey AND rs.rank <= 5
JOIN 
    TopCustomers tp ON rs.s_suppkey = tp.c_custkey
JOIN 
    HighValueParts hs ON hs.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
WHERE 
    LENGTH(tp.top_customer) > 10 
ORDER BY 
    r.r_name, ns.n_name, tp.o_totalprice DESC;
