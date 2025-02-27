WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        CASE 
            WHEN p.p_retailprice > (
                SELECT AVG(p2.p_retailprice) 
                FROM part p2 
                WHERE p2.p_size = p.p_size
            ) THEN 'Above Average' 
            ELSE 'Below Average' 
        END AS price_cat
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost < 100)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal IS NOT NULL AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
)
SELECT 
    r.rnk,
    fs.p_name,
    fs.price_cat,
    co.c_name,
    SUM(co.total_spent) AS total_spent 
FROM 
    RankedSuppliers r
LEFT JOIN 
    FilteredParts fs ON r.rnk <= 3
FULL OUTER JOIN 
    CustomerOrders co ON r.s_nationkey = co.c_custkey
WHERE 
    (fs.p_retailprice IS NOT NULL OR co.total_spent IS NOT NULL)
    AND (fs.price_cat = 'Above Average' OR co.total_spent > 1000)
GROUP BY 
    r.rnk, fs.p_name, fs.price_cat, co.c_name
HAVING 
    SUM(co.total_spent) > COALESCE((SELECT AVG(total_spent) FROM CustomerOrders), 0)
ORDER BY 
    r.rnk DESC, total_spent DESC;
