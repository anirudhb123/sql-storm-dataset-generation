WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS PartRank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.TotalCost
    FROM 
        RankedParts rp
    WHERE 
        rp.PartRank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    to.p_partkey,
    to.p_name,
    to.p_mfgr,
    to.p_brand,
    co.c_custkey,
    co.c_name,
    co.TotalSpent
FROM 
    TopParts to
JOIN 
    lineitem l ON l.l_partkey = to.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer co ON o.o_custkey = co.c_custkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    to.TotalCost DESC, co.TotalSpent DESC
LIMIT 50;
