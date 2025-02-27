WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS acctbal_rank,
        s.s_acctbal
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        (SELECT COUNT(DISTINCT s.s_suppkey) FROM supplier s WHERE s.s_nationkey = n.n_nationkey) AS supplier_count,
        n.n_comment
    FROM 
        nation n
    WHERE 
        (SELECT COUNT(*) FROM supplier s WHERE s.s_nationkey = n.n_nationkey) > 10
),
EligibleParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown'
            ELSE CAST(p.p_size AS VARCHAR)
        END AS size_description
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type
        )
)
SELECT 
    fn.n_name,
    rp.s_name AS richest_supplier,
    co.order_count,
    co.total_spent,
    ep.p_name,
    ep.size_description,
    ep.p_retailprice
FROM 
    FilteredNation fn
LEFT JOIN 
    RankedSuppliers rp ON fn.n_nationkey = rp.s_nationkey AND rp.acctbal_rank = 1
JOIN 
    CustomerOrders co ON co.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = fn.n_nationkey 
        AND c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = fn.n_nationkey
        )
    )
LEFT JOIN 
    EligibleParts ep ON ep.p_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        WHERE ps.ps_availqty < (
            SELECT AVG(ps2.ps_availqty) 
            FROM partsupp ps2 
            WHERE ps2.ps_suppkey IN (
                SELECT DISTINCT s.s_suppkey 
                FROM supplier s 
                WHERE s.s_nationkey = fn.n_nationkey
            )
        )
    )
WHERE 
    fn.supplier_count IS NOT NULL 
ORDER BY 
    fn.n_name, co.total_spent DESC;
