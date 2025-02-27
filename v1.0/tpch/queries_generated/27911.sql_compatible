
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_size, 
        s.s_name AS supplier_name, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        LENGTH(p.p_name) > 10 
        AND p.p_size BETWEEN 1 AND 100
),
FilteredNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name 
    FROM 
        nation n
    WHERE 
        LENGTH(n.n_name) <= 10
),
SupplierOrderCounts AS (
    SELECT 
        s.s_suppkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count 
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_size, 
    rp.supplier_name, 
    fn.n_name AS nation_name, 
    soc.order_count
FROM 
    RankedParts rp
JOIN 
    FilteredNations fn ON fn.n_nationkey = (
        SELECT n.n_nationkey 
        FROM supplier s 
        JOIN nation n ON s.s_nationkey = n.n_nationkey 
        WHERE s.s_name = rp.supplier_name 
        LIMIT 1
    )
JOIN 
    SupplierOrderCounts soc ON soc.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = rp.p_partkey 
        ORDER BY ps.ps_supplycost
        LIMIT 1
    )
WHERE 
    rp.rank = 1
ORDER BY 
    rp.p_size DESC, rp.p_name;
