WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CHAR_LENGTH(p.p_name) AS name_length,
        COUNT(ps.ps_partkey) AS supplier_count,
        RANK() OVER (PARTITION BY CHAR_LENGTH(p.p_name) ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2022-01-01' 
        AND o.o_orderdate < '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.supplier_count,
    rp.rank_by_price,
    tr.r_name,
    co.c_name,
    co.total_spent
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    TopRegions tr ON s.s_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_regionkey = tr.r_regionkey
    )
JOIN 
    CustomerOrders co ON co.total_spent > 10000
WHERE 
    rp.rank_by_price <= 5
ORDER BY 
    total_spent DESC, supplier_count DESC, name_length DESC;
