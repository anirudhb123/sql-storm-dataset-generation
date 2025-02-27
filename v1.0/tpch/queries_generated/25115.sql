WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        SUBSTRING(p.p_comment FROM 1 FOR 20) AS short_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
),

DistinctNations AS (
    SELECT DISTINCT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),

CustomerOrderStats AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)

SELECT 
    rp.p_name,
    rp.short_comment,
    dn.n_name,
    dn.supplier_count,
    cos.c_name,
    cos.total_orders,
    cos.total_spent
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation dn ON s.s_nationkey = dn.n_nationkey
JOIN 
    CustomerOrderStats cos ON cos.total_spent > 10000
WHERE 
    rp.rank_price <= 5
ORDER BY 
    dn.n_name, rp.p_name;
