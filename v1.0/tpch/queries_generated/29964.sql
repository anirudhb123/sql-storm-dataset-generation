WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        LENGTH(p.p_comment) > 10
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 5
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
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    n.n_name AS supplier_nation,
    c.total_spent
FROM 
    RankedParts p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    FilteredNations n ON s.s_nationkey = n.n_nationkey
JOIN 
    CustomerOrders c ON c.c_custkey IN (
        SELECT DISTINCT o.o_custkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_partkey = p.p_partkey
    )
WHERE 
    p.rank <= 3
ORDER BY 
    p.p_brand, p.p_retailprice DESC, c.total_spent DESC;
