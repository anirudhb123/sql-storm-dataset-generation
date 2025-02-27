WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%quality%'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        COUNT(ps.ps_partkey) > 10
),
RecentHighOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
        AND o.o_totalprice > 1000
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ts.s_name AS supplier_name,
    r.h_name AS region_name,
    rho.o_orderkey,
    rho.o_totalprice,
    rho.o_orderdate
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey LIMIT 1)
JOIN 
    nation n ON ts.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    RecentHighOrders rho ON rho.o_totalprice > rp.p_retailprice
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC, 
    rho.o_orderdate DESC;
