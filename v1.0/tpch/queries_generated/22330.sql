WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey,
        (
            SELECT AVG(ps_supplycost) 
            FROM partsupp 
            WHERE ps_suppkey = s.s_suppkey
        ) as avg_supplycost
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey
),
NationWithParts AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT p.p_partkey) > 5 AND SUM(ps.ps_availqty) IS NOT NULL
)
SELECT 
    np.n_name,
    np.part_count,
    np.total_available_qty,
    COALESCE(rp.p_name, 'No parts available') AS top_part_name,
    rp.p_retailprice
FROM 
    NationWithParts np
LEFT JOIN 
    RankedParts rp ON np.part_count > 0 AND np.n_name LIKE '%' || rp.p_name || '%'
WHERE 
    np.total_available_qty IS NOT NULL
ORDER BY 
    np.total_available_qty DESC, rp.price_rank
FETCH FIRST 10 ROWS ONLY;
